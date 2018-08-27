WITH leftone AS 
	(/*  INSERT INTO OHDSI_KTPH.dbo.condition_occurrence(person_id,
														condition_concept_id, 
														condition_start_date, 
														condition_start_datetime,
														condition_source_value,
														condition_end_date,
														condition_end_datetime,
														condition_type_concept_id,
														visit_occurence_id,




	 */ 
	SELECT PD2.secondary_diag_t, PD2.icd_clean , (count(PD2.icd_clean)/ 11613.56) AS frequency
		   /* VO.person_id, 
		   C.concept_id,
		   visit_start_date,
		   visit_start_datetime,
		   icd_clean,
		   visit_end_date,
		   visit_end_datetime,
		   0,
		   visit_occurence_id, 

			*/

	FROM Saphire_KTPH.dbo.t_secondary_diagnosis PD2 
		INNER JOIN OHDSI_KTPH.dbo.visit_id_source_mapping VISD 
		ON PD2.encounter_id = VISD.encounter_id
			COLLATE SQL_Latin1_General_CP1_CI_AS
			AND PD2.pat_type_cd = VISD.pat_type_cd
			COLLATE SQL_Latin1_General_CP1_CI_AS 
		INNER JOIN OHDSI_KTPH.dbo.visit_occurrence VO
		ON VISD.visit_occurrence_id = VO.visit_occurrence_id 
		LEFT OUTER JOIN OHDSI_KTPH.dbo.concept C
		ON PD2.icd_clean = C.concept_code 
			COLLATE SQL_Latin1_General_CP1_CI_AS
		LEFT OUTER JOIN OHDSI_KTPH.dbo.CONCEPT_RELATIONSHIP CR
		ON C.concept_id = CR.concept_id_1
		AND (C.vocabulary_id LIKE 'ICD%' 
			OR C.vocabulary_id IS NULL) 
		AND CR.relationship_id ='Maps to'
	/* delete later */ 
	WHERE C.concept_id is NULL
	GROUP BY PD2.icd_clean, PD2.secondary_diag_t) 

SELECT sum(frequency)
FROM leftone ;


 