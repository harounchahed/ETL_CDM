INSERT INTO OHDSI_KTPH.dbo.visit_occurrence (person_id,
											visit_concept_id,
					  						visit_start_date,
											visit_start_datetime,
											visit_end_date,
											visit_end_datetime,
											/* provide_id - does not apply to KTPH*/ 
											visit_source_value,
											visit_type_concept_id)
 										
SELECT     
	p.person_id,    	
	CASE 
	WHEN te.pat_type_cd = 'I' or te.pat_type_cd = 'EL' THEN 9201 /* Impatient or Elective Impatient */ 
	WHEN te.pat_type_cd  = 'O' THEN 9202 /* outpatient */
	WHEN te.pat_type_cd  = 'E' or te.pat_type_cd ='EM' THEN 9203 /* Emergency */
	ELSE 0 /* unknown */
	END AS visit_concept_id,
	
	CONVERT(date, te.adm_dt),
	CONVERT(time, te.adm_dt),
	CONVERT(date, te.disch_dt),
	CONVERT(time, te.disch_dt), 
	te.pat_type_cd,
	44818518
	
FROM Saphire_KTPH.dbo.t_encounter te INNER JOIN OHDSI_KTPH.dbo.person p 
									 ON p.person_source_value = te.person_id 
-- JOIN serves to retrieve the person_id on OHDSI.dbo.person table, and not the one on Saphire_KTPH.dbo.t_demographics 
WHERE te.adm_dt IS NOT NULL 
AND te.disch_dt IS NOT NULL 
-- each visit record musht have valid admission and discharge dates; 




 