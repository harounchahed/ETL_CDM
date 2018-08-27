/*  INSERT INTO OHDSI_KTPH.dbo.condition_occurrence(person_id,
													condition_concept_id, 
													condition_start_date, 
													condition_start_datetime,
													condition_source_value,
													condition_end_date,
													condition_end_datetime,
													condition_type_concept_id,
													visit_occurence_id,




	*/ 
SELECT 
			CASE 
				 WHEN PD2.icd_clean LIKE 'T._.__' 
				 THEN SUBSTRING (PD2.icd_clean, 3, 1) + SUBSTRING (PD2.icd_clean, 5, LEN (PD2.icd_clean) - 4)
				 WHEN PD2.icd_clean LIKE 'T._._%_%_' 
				 THEN  SUBSTRING (PD2.icd_clean, 3, 1) 
				 + SUBSTRING (PD2.icd_clean, 5, 2) 

				 +'.'
				 + SUBSTRING (PD2.icd_clean, 7, LEN (PD2.icd_clean) - 6) 
				 ELSE PD2.icd_clean 
			END AS icd_cleaner, 
			icd_clean
FROM Saphire_KTPH.dbo.t_secondary_diagnosis PD2 
WHERE PD2.icd_clean LIKE 'T._._%' ; 


 