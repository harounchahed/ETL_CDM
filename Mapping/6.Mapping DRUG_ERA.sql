WITH cteDrugTarget (DRUG_EXPOSURE_ID, 
					PERSON_ID,
					DRUG_CONCEPT_ID, 
					DRUG_TYPE_CONCEPT_ID, 
					DRUG_EXPOSURE_START_DATE, 
					DRUG_EXPOSURE_END_DATE) as
	(
	-- Normalize DRUG_EXPOSURE_END_DATE to either the existing drug exposure end date, or add days supply, or add 1 day to the start date
	SELECT d.DRUG_EXPOSURE_ID, 
	       d. PERSON_ID, 
		   c.CONCEPT_ID, 
		   d.DRUG_TYPE_CONCEPT_ID, 
		   DRUG_EXPOSURE_START_DATE, 
		   COALESCE(DRUG_EXPOSURE_END_DATE, DATEADD(day,DAYS_SUPPLY,DRUG_EXPOSURE_START_DATE), DATEADD(day,1,DRUG_EXPOSURE_START_DATE)) as DRUG_EXPOSURE_END_DATE
	FROM OHDSI_KTPH.dbo.DRUG_EXPOSURE d
	JOIN OHDSI_KTPH.dbo.CONCEPT_ANCESTOR ca on ca.DESCENDANT_CONCEPT_ID = d.DRUG_CONCEPT_ID
	JOIN OHDSI_KTPH.dbo.CONCEPT c on ca.ANCESTOR_CONCEPT_ID = c.CONCEPT_ID
	WHERE c.VOCABULARY_ID = 'RxNorm'
	AND c.CONCEPT_CLASS_ID = 'Ingredient'
	),

cteEndDates (PERSON_ID, 
		     DRUG_CONCEPT_ID, 
			 END_DATE) as -- the magic
	(
	select PERSON_ID, 
		   DRUG_CONCEPT_ID, 
		   DATEADD(day,-30,EVENT_DATE) as END_DATE -- unpad the end date
	FROM
		(
		select PERSON_ID, DRUG_CONCEPT_ID, EVENT_DATE, EVENT_TYPE, 
		MAX(START_ORDINAL) OVER (PARTITION BY PERSON_ID, DRUG_CONCEPT_ID ORDER BY EVENT_DATE, EVENT_TYPE ROWS UNBOUNDED PRECEDING) as START_ORDINAL, -- this pulls the current START down from the prior rows so that the NULLs from the END DATES will contain a value we can compare with 
		ROW_NUMBER() OVER (PARTITION BY PERSON_ID, DRUG_CONCEPT_ID ORDER BY EVENT_DATE, EVENT_TYPE) AS OVERALL_ORD -- this re-numbers the inner UNION so all rows are numbered ordered by the event date
		from
				(
			-- select the start dates, assigning a row number to each
			Select PERSON_ID, DRUG_CONCEPT_ID, DRUG_EXPOSURE_START_DATE AS EVENT_DATE, -1 as EVENT_TYPE, ROW_NUMBER() OVER (PARTITION BY PERSON_ID, DRUG_CONCEPT_ID ORDER BY DRUG_EXPOSURE_START_DATE) as START_ORDINAL
			from cteDrugTarget
	
			UNION ALL
	
			-- pad the end dates by 30 to allow a grace period for overlapping ranges.
			select PERSON_ID, DRUG_CONCEPT_ID, DATEADD(day,30,DRUG_EXPOSURE_END_DATE), 1 as EVENT_TYPE, NULL
			FROM cteDrugTarget
			) RAWDATA
		) E
	WHERE (2 * E.START_ORDINAL) - E.OVERALL_ORD = 0
	),

cteDrugExposureEnds (PERSON_ID, 
					DRUG_CONCEPT_ID, 
					DRUG_TYPE_CONCEPT_ID, 
					DRUG_EXPOSURE_START_DATE, 
					DRUG_ERA_END_DATE) as
(
select d.PERSON_ID, 
	   d.DRUG_CONCEPT_ID,
	   d.DRUG_TYPE_CONCEPT_ID,
	   d.DRUG_EXPOSURE_START_DATE, 
	   MIN(e.END_DATE) AS ERA_END_DATE
FROM cteDrugTarget d
JOIN cteEndDates e 
	ON d.PERSON_ID = e.PERSON_ID 
	and d.DRUG_CONCEPT_ID = e.DRUG_CONCEPT_ID 
	and e.END_DATE >= d.DRUG_EXPOSURE_START_DATE
GROUP BY d.DRUG_EXPOSURE_ID, 
		 d.PERSON_ID, 
		 d.DRUG_CONCEPT_ID, 
		 d.DRUG_TYPE_CONCEPT_ID, 
		 d.DRUG_EXPOSURE_START_DATE
)
INSERT INTO OHDSI_KTPH.dbo.drug_era(person_id, 
									drug_concept_id, 
									drug_era_start_date,
									drug_era_end_date,
									drug_exposure_count)
SELECT person_id, 
	   drug_concept_id, 
	   min(DRUG_EXPOSURE_START_DATE) as DRUG_ERA_START_DATE, 
	   DRUG_ERA_END_DATE, 
	   COUNT(*) as DRUG_EXPOSURE_COUNT
from cteDrugExposureEnds
GROUP BY person_id, drug_concept_id, drug_type_concept_id, DRUG_ERA_END_DATE
ORDER BY person_id, drug_concept_id
;
