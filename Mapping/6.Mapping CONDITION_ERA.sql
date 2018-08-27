WITH cteConditionTarget 
	(CONDITION_OCCURRENCE_ID, 
	PERSON_ID, 
	CONDITION_CONCEPT_ID, 
	CONDITION_TYPE_CONCEPT_ID, 
	CONDITION_START_DATE, 
	CONDITION_END_DATE) AS 

	(SELECT co.CONDITION_OCCURRENCE_ID, 
			co.PERSON_ID, 
			co.CONDITION_CONCEPT_ID, 
			co.CONDITION_TYPE_CONCEPT_ID, 
			co.CONDITION_START_DATE,
	COALESCE(co.CONDITION_END_DATE, DATEADD(day,1,CONDITION_START_DATE)) AS CONDITION_END_DATE
	FROM OHDSI_KTPH.dbo.CONDITION_OCCURRENCE co),


cteEndDates (PERSON_ID,
			 CONDITION_CONCEPT_ID, 
			 END_DATE) AS -- the magic
	(SELECT PERSON_ID, 
			CONDITION_CONCEPT_ID, 
			DATEADD (day,-30,EVENT_DATE) AS END_DATE -- unpad the end date
	FROM
	(
		SELECT PERSON_ID, 
			   CONDITION_CONCEPT_ID, 
			   EVENT_DATE, 
			   EVENT_TYPE, 
			   MAX(START_ORDINAL) OVER 
					(PARTITION BY PERSON_ID, CONDITION_CONCEPT_ID 
					ORDER BY EVENT_DATE, EVENT_TYPE 
					ROWS UNBOUNDED PRECEDING) as START_ORDINAL, -- this pulls the current START down from the prior rows so that the NULLs from the END DATES will contain a value we can compare with 
			   ROW_NUMBER() OVER (PARTITION BY PERSON_ID, 
											   CONDITION_CONCEPT_ID 
								  ORDER BY EVENT_DATE, EVENT_TYPE) AS OVERALL_ORD -- this re-numbers the inner UNION so all rows are numbered ordered by the event date
		FROM
			(
			-- select the start dates, assigning a row number to each
			SELECT PERSON_ID, 
				   CONDITION_CONCEPT_ID, 
				   CONDITION_START_DATE AS EVENT_DATE, 
				   -1 as EVENT_TYPE, 
				   ROW_NUMBER() OVER (PARTITION BY PERSON_ID, 
												   CONDITION_CONCEPT_ID 
									  ORDER BY CONDITION_START_DATE) as START_ORDINAL
			FROM cteConditionTarget

			UNION ALL

			-- pad the end dates by 30 to allow a grace period for overlapping ranges.
			SELECT PERSON_ID, 
				   CONDITION_CONCEPT_ID, 
				   DATEADD(day,30,CONDITION_END_DATE), 
				   1 as EVENT_TYPE, 
				   NULL
			FROM cteConditionTarget
			) RAWDATA
	) E

	WHERE (2 * E.START_ORDINAL) - E.OVERALL_ORD = 0
	),

cteConditionEnds (PERSON_ID, 
				  CONDITION_CONCEPT_ID, 
				  CONDITION_TYPE_CONCEPT_ID, 
				  CONDITION_START_DATE, ERA_END_DATE) as
	(select c.PERSON_ID, 
		   c.CONDITION_CONCEPT_ID,
		   c.CONDITION_TYPE_CONCEPT_ID,
		   c.CONDITION_START_DATE, 
		   MIN(e.END_DATE) as ERA_END_DATE
	FROM cteConditionTarget c
	JOIN cteEndDates e 
	ON c.PERSON_ID = e.PERSON_ID 
	   and c.CONDITION_CONCEPT_ID = e.CONDITION_CONCEPT_ID 
	   and e.END_DATE >= c.CONDITION_START_DATE
	GROUP BY 
	c.PERSON_ID, 
	c.CONDITION_CONCEPT_ID,
	c.CONDITION_TYPE_CONCEPT_ID,
	c.CONDITION_START_DATE )

INSERT INTO OHDSI_KTPH.dbo.condition_era (person_id, 
										  condition_concept_id, 
										  condition_era_start_date, 
										  condition_era_end_date,
										  condition_occurrence_count)
SELECT person_id, 
	   CONDITION_CONCEPT_ID, 
	   min(CONDITION_START_DATE) as CONDITION_ERA_START_DATE, 
	   ERA_END_DATE as CONDITION_ERA_END_DATE, 
	   COUNT(*) as CONDITION_OCCURRENCE_COUNT
FROM cteConditionEnds
GROUP BY person_id, CONDITION_CONCEPT_ID, CONDITION_TYPE_CONCEPT_ID, ERA_END_DATE
ORDER BY person_id, CONDITION_CONCEPT_ID
