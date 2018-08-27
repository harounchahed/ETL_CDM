WITH Drug_Selection_11 AS 
	(SELECT VO.person_id as person_id, 
			CONVERT (date, IMO.drug_order_start_dt) as drug_exposure_start_date,
			CONVERT (time, IMO.drug_order_start_dt) as drug_exposure_start_time,
			CONVERT (date, IMO.drug_order_end_dt) as drug_exposure_end_date,
			CONVERT (time, IMO.drug_order_end_dt) as drug_exposure_end_time,
			581373 as drug_type_concept_id, -- Physician administrated drug
			VO.visit_occurrence_id as visit_occurrence_id, 
			IMO.drug_inpat_order_ingred_clean as drug_source_value, -- source value 
			MIN(C.concept_id) as drug_source_concept_id, -- we search min because we group by all other columns 
														 -- this is because some drugs have the same name ore are registered more than once 
			route_adm_cd as route_source_value, 
			strength as dose_unit_source_value 

	FROM Saphire_KTPH.dbo.t_inpatient_med_order IMO
		LEFT OUTER JOIN OHDSI_KTPH.dbo.visit_id_source_mapping VISD -- join with VISD to link the PK of IMO with the PK of VO
		ON IMO.encounter_id = VISD.encounter_id
			COLLATE SQL_Latin1_General_CP1_CI_AS 
			AND IMO.pat_type_cd = VISD.pat_type_cd
			COLLATE SQL_Latin1_General_CP1_CI_AS 
		LEFT OUTER JOIN OHDSI_KTPH.dbo.visit_occurrence VO -- join with VO to select the vist_id from OHDSI_KTPH.dbo.visit_id and not from Saphire_KTPH.dbo.t_encoutner
		ON VISD.visit_occurrence_id = VO.visit_occurrence_id  
		LEFT OUTER JOIN OHDSI_KTPH.dbo.concept C
		ON IMO.drug_inpat_order_ingred_clean = C.concept_name 
		COLLATE SQL_Latin1_General_CP1_CI_AS 
		/* ON CAST (IMO.drug_inpat_order_clean_cd as VARCHAR(100)) = C.concept_code */
		AND C.domain_id = 'Drug' -- condition on domain 
		-- AND C.invalid_reason NOT IN ('U', 'D') --AND C.invalid_reason NOT IN ('D','U') -- ICD code has no been Deleted ('D') or Updated ('U') 
		WHERE C.concept_id IS NOT NULL
		GROUP BY VO.person_id, 
			CONVERT (date, IMO.drug_order_start_dt),
			CONVERT (time, IMO.drug_order_start_dt),
			CONVERT (date, IMO.drug_order_end_dt),
			CONVERT (time, IMO.drug_order_end_dt),
			VO.visit_occurrence_id, 
			IMO.drug_inpat_order_ingred_clean,  
			route_adm_cd, 
			strength),

Drug_Selection_12 AS 
	(SELECT person_id, 
			CR.concept_id_2 as drug_concept_id, 
			drug_exposure_start_date,
			drug_exposure_start_time,
			drug_exposure_end_date,
			drug_exposure_end_time,
			581373 as drug_type_concept_id, -- Physician administrated drug
			visit_occurrence_id, 
			drug_source_value, 
			drug_source_concept_id, 
			route_source_value, 
			dose_unit_source_value 

	FROM Drug_Selection_11 DS11
		LEFT OUTER JOIN OHDSI_KTPH.dbo.CONCEPT_RELATIONSHIP CR
		ON DS11.drug_source_concept_id = CR.concept_id_1
		AND CR.relationship_id ='Maps to'
	WHERE DS11.drug_source_concept_id IS NOT NULL),

-- Drug_Selection_12 contains 90% of the mapped data 
-- the other 10% is all the compositions of different durgs 
-- Dr.Sung mapped all these drugs manually on the table OHDSI_KTPH.dbo.manually_mapped_drugs MMD 
-- in Drug_Selection_2 we match the compositions to their manually mapped standardized codes


Drug_Selection_2 AS 
	(SELECT VO.person_id as person_id, 
			CR.concept_id_2 as drug_concept_id, 
			CONVERT (date, IMO.drug_order_start_dt) as drug_exposure_start_date,
			CONVERT (time, IMO.drug_order_start_dt) as drug_exposure_start_time,
			CONVERT (date, IMO.drug_order_end_dt) as drug_exposure_end_date,
			CONVERT (time, IMO.drug_order_end_dt) as drug_exposure_end_time,
			581373 as drug_type_concept_id, -- Physician administrated drug
			VO.visit_occurrence_id as visit_occurrence_id, 
			IMO.drug_inpat_order_ingred_clean as drug_source_value, 
			CR.concept_id_2 as drug_source_concept_id, 
			route_adm_cd as route_source_value, 
			strength as dose_unit_source_value 
	
	FROM Saphire_KTPH.dbo.t_inpatient_med_order IMO
		LEFT OUTER JOIN OHDSI_KTPH.dbo.visit_id_source_mapping VISD 
		ON IMO.encounter_id = VISD.encounter_id
			COLLATE SQL_Latin1_General_CP1_CI_AS 
			AND IMO.pat_type_cd = VISD.pat_type_cd
			COLLATE SQL_Latin1_General_CP1_CI_AS 
		LEFT OUTER JOIN OHDSI_KTPH.dbo.visit_occurrence VO
		ON VISD.visit_occurrence_id = VO.visit_occurrence_id  
		LEFT OUTER JOIN OHDSI_KTPH.dbo.manually_mapped_drugs MMD 
		ON IMO.drug_inpat_order_ingred_clean = MMD.clean_drug_name 
		COLLATE SQL_Latin1_General_CP1_CI_AS 
		AND IMO.drug_inpat_order_unclean = MMD.[unclean_drug_name ]   
		COLLATE SQL_Latin1_General_CP1_CI_AS
		LEFT OUTER JOIN OHDSI_KTPH.dbo.CONCEPT_RELATIONSHIP CR
		ON MMD.[OMOP Standard Code] = CR.concept_id_1 
		AND CR.relationship_id ='Maps to'
		
	WHERE IMO.drug_inpat_order_ingred_clean NOT IN (SELECT DS12.drug_source_value
													FROM  Drug_Selection_12 DS12)
	AND MMD.[OMOP Standard Code] IS NOT NULL)

INSERT INTO OHDSI_KTPH.dbo.drug_exposure (person_id,	
										  drug_concept_id, 
										  drug_exposure_start_date,
										  drug_exposure_start_datetime, 
										  drug_exposure_end_date, 
										  drug_exposure_end_datetime,
										  drug_type_concept_id, 
										  visit_occurrence_id, 
										  drug_source_value,
										  drug_source_concept_id, 
										  route_source_value, 
										  dose_unit_source_value)

SELECT * FROM Drug_Selection_12 DS12 
	WHERE DS12.person_id IS NOT NULL 
	AND DS12.visit_occurrence_id IS NOT NULL
	AND DS12.drug_concept_id IS NOT NULL
	AND DS12.drug_exposure_start_date IS NOT NULL
	AND DS12.drug_exposure_end_date IS NOT NULL
	AND DS12.drug_exposure_start_time IS NOT NULL
	AND DS12.drug_exposure_end_time IS NOT NULL

UNION ALL 

SELECT * 
FROM Drug_Selection_2 DS2
	WHERE DS2.person_id IS NOT NULL 
	AND DS2.visit_occurrence_id IS NOT NULL
	AND DS2.drug_concept_id IS NOT NULL
	AND DS2.drug_exposure_start_date IS NOT NULL
	AND DS2.drug_exposure_end_date IS NOT NULL
	AND DS2.drug_exposure_start_time IS NOT NULL
	AND DS2.drug_exposure_end_time IS NOT NULL										 
