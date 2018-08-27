/*INSERT INTO OHDSI_KTPH.dbo.condition_occurrence(person_id,
													condition_concept_id, 
													condition_start_date, 
													condition_start_datetime,
													condition_end_date,
													condition_end_datetime,
													condition_type_concept_id,
													visit_occurrence_id,
													condition_source_value, 
													condition_source_concept_id)
													*/
WITH Condition_Selection_1 AS  
	(SELECT PD1.icd_clean as icd,
		    VO.person_id, 
		   CR.concept_id_2,
		   VO.visit_start_date,
		   VO.visit_start_datetime,
		   VO.visit_end_date,
		   VO.visit_end_datetime,
		   32020 as condition_type_concept_id, 
		   VO.visit_occurrence_id,
		   PD1.icd_clean,
		   C.concept_id  

	FROM Saphire_KTPH.dbo.t_primary_diagnosis PD1 
		INNER JOIN OHDSI_KTPH.dbo.visit_id_source_mapping VISD 
		ON PD1.encounter_id = VISD.encounter_id
			COLLATE SQL_Latin1_General_CP1_CI_AS
			AND PD1.pat_type_cd = VISD.pat_type_cd
			COLLATE SQL_Latin1_General_CP1_CI_AS 
		INNER JOIN OHDSI_KTPH.dbo.visit_occurrence VO
		ON VISD.visit_occurrence_id = VO.visit_occurrence_id 
		LEFT OUTER JOIN OHDSI_KTPH.dbo.concept C
		ON PD1.icd_clean = C.concept_code 
		COLLATE SQL_Latin1_General_CP1_CI_AS
		AND (C.vocabulary_id = 'ICD10CM')
		AND C.domain_id = 'Condition'
		AND C.invalid_reason NOT IN ('D','U')    
		LEFT OUTER JOIN OHDSI_KTPH.dbo.CONCEPT_RELATIONSHIP CR 
		ON C.concept_id = CR.concept_id_1
		AND CR.relationship_id ='Maps to'
	WHERE C.concept_id IS NOT NULL),

Condition_Selection_2 AS  
	(SELECT PD1.icd_clean as icd,
		    VO.person_id, 
		   CR.concept_id_2,
		   VO.visit_start_date,
		   VO.visit_start_datetime,
		   VO.visit_end_date,
		   VO.visit_end_datetime,
		   32020 as condition_type_concept_id, 
		   VO.visit_occurrence_id,
		   PD1.icd_clean,
		   C.concept_id  

	FROM Saphire_KTPH.dbo.t_primary_diagnosis PD1 
		INNER JOIN OHDSI_KTPH.dbo.visit_id_source_mapping VISD 
		ON PD1.encounter_id = VISD.encounter_id
			COLLATE SQL_Latin1_General_CP1_CI_AS
			AND PD1.pat_type_cd = VISD.pat_type_cd
			COLLATE SQL_Latin1_General_CP1_CI_AS 
		INNER JOIN OHDSI_KTPH.dbo.visit_occurrence VO
		ON VISD.visit_occurrence_id = VO.visit_occurrence_id 
		LEFT OUTER JOIN OHDSI_KTPH.dbo.concept C
		ON PD1.icd_clean = C.concept_code 
		COLLATE SQL_Latin1_General_CP1_CI_AS
		AND (C.vocabulary_id = 'ICD9CM')
		AND C.domain_id = 'Condition'
		AND C.invalid_reason NOT IN ('D','U')    
		LEFT OUTER JOIN OHDSI_KTPH.dbo.CONCEPT_RELATIONSHIP CR 
		ON C.concept_id = CR.concept_id_1
		AND CR.relationship_id ='Maps to'
	WHERE C.concept_id IS NOT NULL
	AND PD1.icd_clean NOT IN (SELECT icd FROM 
										   Condition_Selection_1)),
Condition_Selection_3 AS  
	(SELECT PD1.icd_clean as icd,
		    VO.person_id, 
		   CR.concept_id_2,
		   VO.visit_start_date,
		   VO.visit_start_datetime,
		   VO.visit_end_date,
		   VO.visit_end_datetime,
		   32020 as condition_type_concept_id, 
		   VO.visit_occurrence_id,
		   PD1.icd_clean,
		   C.concept_id  

	FROM Saphire_KTPH.dbo.t_primary_diagnosis PD1 
		INNER JOIN OHDSI_KTPH.dbo.visit_id_source_mapping VISD 
		ON PD1.encounter_id = VISD.encounter_id
			COLLATE SQL_Latin1_General_CP1_CI_AS
			AND PD1.pat_type_cd = VISD.pat_type_cd
			COLLATE SQL_Latin1_General_CP1_CI_AS 
		INNER JOIN OHDSI_KTPH.dbo.visit_occurrence VO
		ON VISD.visit_occurrence_id = VO.visit_occurrence_id 
		LEFT OUTER JOIN OHDSI_KTPH.dbo.concept C
		ON PD1.icd_clean = C.concept_code 
		COLLATE SQL_Latin1_General_CP1_CI_AS
		AND (C.vocabulary_id = 'ICD10')
		AND C.domain_id = 'Condition'
		AND C.invalid_reason NOT IN ('D','U')    
		LEFT OUTER JOIN OHDSI_KTPH.dbo.CONCEPT_RELATIONSHIP CR 
		ON C.concept_id = CR.concept_id_1
		AND CR.relationship_id ='Maps to'
	WHERE C.concept_id IS NOT NULL
	AND PD1.icd_clean NOT IN (SELECT icd FROM 
										   Condition_Selection_1)
    AND PD1.icd_clean NOT IN (SELECT icd FROM 
										   Condition_Selection_2)),
Final_Condition_Selection AS 
	(SELECT * FROM Condition_Selection_1
	 UNION ALL
	 SELECT * FROM Condition_Selection_2 
	 UNION ALL
	 SELECT * FROM Condition_Selection_3)


select TOP 1000 * from Final_Condition_Selection ; 


 