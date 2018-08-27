INSERT INTO OHDSI_KTPH.dbo.visit_id_source_mapping(encounter_id, 
													pat_type_cd)

SELECT 
	te.encounter_id, 
	te.pat_type_cd
	
FROM Saphire_KTPH.dbo.t_encounter te INNER JOIN OHDSI_KTPH.dbo.person p 
									 ON p.person_source_value = te.person_id 
WHERE te.adm_dt IS NOT NULL 
	AND te.disch_dt IS NOT NULL; 