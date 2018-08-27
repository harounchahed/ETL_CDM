/* map patient who have at least a year of birth */ 
INSERT INTO OHDSI_KTPH.dbo.person (gender_concept_id, 
						year_of_birth, 
						month_of_birth,
						day_of_birth, 
						race_concept_id, 
						location_id, 
						ethnicity_concept_id,
						person_source_value, 
						gender_source_value,
						race_source_value,
						ethnicity_source_value) 
SELECT 
-- person_id is auto-incremented
CASE 
	WHEN sex_cd = 'M' THEN 8507
	WHEN sex_cd = 'F' THEN 8532 
	ELSE 8551
	END AS gender_concept_id,
-- 'M' and 'F' are already the OMOP standardized values for sec so we just map them to their concept_ids
-- since there are few values (3), there is no need to use the Concept_Relationship table 
-- we just include the values manually in the code
DATEPART(YEAR, birth_d) AS year_of_birth,
DATEPART(MONTH, birth_d) AS month_of_birth,
DATEPART(DAY, birth_d) AS day_of_birth,
CASE 
	WHEN race_cd ='C' THEN 38003579 -- Chinese 
	WHEN race_cd = 'E' THEN 100 -- Eurasian 
	WHEN race_cd = 'I' OR race_cd = 'S' THEN 100 --Indian or Sikh 
	WHEN race_cd ='J' THEN 38003584 -- Japanese 
	WHEN race_cd = 'M' THEN 38003587 -- Malay
	WHEN race_cd = 'N' THEN 8527 -- White
	ELSE 0 -- Other
	END AS race_concept_id,
1, -- location_id for KTPH - check OHDSI_KTPH.dbo.location for other loaction_ids  
CASE 
	WHEN race_cd ='C' THEN 38003579 -- Chinese 
	WHEN race_cd = 'E' THEN 100 -- Eurasian 
	WHEN race_cd = 'I' OR race_cd = 'S' THEN 100 --Indian or Sikh 
	WHEN race_cd ='J' THEN 38003584 -- Japanese 
	WHEN race_cd = 'M' THEN 38003587 -- Malay
	WHEN race_cd = 'N' THEN 8527 -- White
	ELSE 0 -- Other
	END AS ethnicity_concept_id,
person_id, -- source value
sex_cd, -- source value
race_cd, -- source value
race_cd-- source value

FROM Saphire_KTPH.dbo.t_demographics
WHERE  DATEPART(YEAR, birth_d) IS NOT NULL 
-- each patient on the CMD must have a valid date of birth; 