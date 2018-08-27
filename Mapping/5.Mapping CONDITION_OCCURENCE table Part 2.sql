-- To understand the steps taken to map the conditions, check out this figure 
-- insert link to google slide here
-- if you want to understand how the ICD code is modified at each step, check out the full presentation 


WITH [Condition_Selection_1] AS  
	(SELECT VO.person_id as person_id, 
		   VO.visit_start_date as condition_start_date,
		   VO.visit_start_datetime as condition_start_datetime,
		   VO.visit_end_date as condition_end_date,
		   VO.visit_end_datetime as condition_end_datetime,
		   44786629 as condition_type_concept_id, -- standardized concept_id for secondary condition
		   VO.visit_occurrence_id as visit_occurrence_id,
		   PD2.icd_clean as condition_source_value,
		   MAX(C.concept_id) as condition_source_concept_id -- we select max because we group by all other columns
		                                                    -- this is to take account for the ICD codes that are in multiple dictionaries 
															-- for instance, ICD9 and ICD9CM 
	FROM Saphire_KTPH.dbo.t_secondary_diagnosis PD2 
		INNER JOIN OHDSI_KTPH.dbo.visit_id_source_mapping VISD -- join with VISD to link the PK of PD2 with the PK of VO
		ON PD2.encounter_id = VISD.encounter_id
			COLLATE SQL_Latin1_General_CP1_CI_AS
			AND PD2.pat_type_cd = VISD.pat_type_cd
			COLLATE SQL_Latin1_General_CP1_CI_AS 
		INNER JOIN OHDSI_KTPH.dbo.visit_occurrence VO -- join with VO to select the vist_id from OHDSI_KTPH.dbo.visit_id and not from Saphire_KTPH.dbo.t_encoutner
		ON VISD.visit_occurrence_id = VO.visit_occurrence_id 
		LEFT OUTER JOIN OHDSI_KTPH.dbo.concept C
		ON PD2.icd_clean = C.concept_code 
		COLLATE SQL_Latin1_General_CP1_CI_AS
		AND (C.vocabulary_id LIKE 'ICD%') -- any ICD dictionary (ICD9, ICD10, ICD9CM, ICD0CM)
		AND C.domain_id = 'Condition' -- condition on domain 
		-- AND C.invalid_reason NOT IN ('D','U') -- ICD code has no been Deleted ('D') or Updated ('U') 
	GROUP BY PD2.icd_clean,
		    VO.person_id, 
		   VO.visit_start_date,
		   VO.visit_start_datetime,
		   VO.visit_end_date,
		   VO.visit_end_datetime,
		   VO.visit_occurrence_id,
		   PD2.icd_clean
		   ),

[Condition_Selection_11] AS  
	(SELECT * 
	 FROM Condition_Selection_1 CS1
	 WHERE CS1.condition_source_concept_id IS NOT NULL), 


	
[Condition_Selection_111] AS  
	(SELECT CS11.person_id,
			CR.concept_id_2 as condition_concept_id, -- first cohort of mapped ICD codes
			CS11.condition_start_date, 
			CS11.condition_start_datetime,
			CS11.condition_end_date,
			CS11.condition_end_datetime,
			CS11.condition_type_concept_id,
			CS11.visit_occurrence_id,
			CS11.condition_source_value, 
			CS11.condition_source_concept_id
	FROM [Condition_Selection_11] CS11 
		LEFT OUTER JOIN OHDSI_KTPH.dbo.CONCEPT_RELATIONSHIP CR 
		ON  CS11.condition_source_concept_id  = CR.concept_id_1
		AND CR.relationship_id ='Maps to'), 

[Condition_Selection_12] AS  
	(SELECT person_id, 
			condition_start_date, 
			condition_start_datetime,
			condition_end_date,
			condition_end_datetime,
			condition_type_concept_id,
			visit_occurrence_id,
			condition_source_value 
			-- condition_source_concept_id
	 FROM Condition_Selection_1 CS1
	 WHERE CS1.condition_source_concept_id IS NULL
	 UNION 
	 SELECT person_id, 
			condition_start_date, 
			condition_start_datetime,
			condition_end_date,
			condition_end_datetime,
			condition_type_concept_id,
			visit_occurrence_id,
			condition_source_value 
	 FROM Condition_Selection_111 CS111
	 WHERE CS111.condition_concept_id IS NULL), 

[Condition_Selection_121] AS  
	(SELECT CS12.person_id,
			-- CR.concept_id_2 as condition_concept_id, 
			CS12.condition_start_date, 
			CS12.condition_start_datetime,
			CS12.condition_end_date,
			CS12.condition_end_datetime,
			CS12.condition_type_concept_id,
			CS12.visit_occurrence_id,
			CS12.condition_source_value, 
			MAX(C.concept_id) as condition_source_concept_id
	FROM [Condition_Selection_12] CS12 
		LEFT OUTER JOIN OHDSI_KTPH.dbo.concept C
		ON 
		-- ICD code is of the format 'T.D.34' then it becomes of the format 'D34' 
		-- else if it is of the format 'T.D.3412' then it becomes of the format 'D34.12' 
		-- else it stays the same
			(CASE 
				 WHEN CS12.condition_source_value LIKE 'T._.__' 
				 THEN SUBSTRING (CS12.condition_source_value, 3, 1)
				 + SUBSTRING (CS12.condition_source_value, 5, LEN (CS12.condition_source_value) - 4)
				 WHEN CS12.condition_source_value LIKE 'T._._%_%_'  -- has at least 3 characters after the second decimal point
				 THEN  SUBSTRING (CS12.condition_source_value, 3, 1) 
				 + SUBSTRING (CS12.condition_source_value, 5, 2) 
				 +'.'
				 + SUBSTRING (CS12.condition_source_value, 7, LEN (CS12.condition_source_value) - 6)
				 ELSE  LEFT(CS12.condition_source_value, LEN(CS12.condition_source_value) - 1) 
			 END = C.concept_code
			 COLLATE SQL_Latin1_General_CP1_CI_AS)
			 AND (C.vocabulary_id LIKE 'ICD%')
			 AND C.domain_id = 'Condition'
			 --AND C.invalid_reason NOT IN ('D','U')
	GROUP BY CS12.person_id,
		CS12.condition_start_date, 
		CS12.condition_start_datetime,
		CS12.condition_end_date,
		CS12.condition_end_datetime,
		CS12.condition_type_concept_id,
		CS12.visit_occurrence_id,
		CS12.condition_source_value
	),

[Condition_Selection_1211] AS  
	(SELECT CS121.person_id,
			CR.concept_id_2 as condition_concept_id, 
			CS121.condition_start_date, 
			CS121.condition_start_datetime,
			CS121.condition_end_date,
			CS121.condition_end_datetime,
			CS121.condition_type_concept_id,
			CS121.visit_occurrence_id,
			CS121.condition_source_value, 
			CS121.condition_source_concept_id
	FROM [Condition_Selection_121] CS121 
		LEFT OUTER JOIN OHDSI_KTPH.dbo.CONCEPT_RELATIONSHIP CR 
		ON  CS121.condition_source_concept_id  = CR.concept_id_1
		AND CR.relationship_id ='Maps to'
	WHERE CS121.condition_source_concept_id IS NOT NULL),

[Condition_Selection_122] AS  
	(SELECT person_id, 
			condition_start_date, 
			condition_start_datetime,
			condition_end_date,
			condition_end_datetime,
			condition_type_concept_id,
			visit_occurrence_id,
			condition_source_value 
			-- condition_source_concept_id
	 FROM Condition_Selection_121 CS121
	 WHERE CS121.condition_source_concept_id IS NULL
	 UNION 
	 SELECT person_id, 
			condition_start_date, 
			condition_start_datetime,
			condition_end_date,
			condition_end_datetime,
			condition_type_concept_id,
			visit_occurrence_id,
			condition_source_value 
	 FROM Condition_Selection_1211 CS1211
	 WHERE CS1211.condition_concept_id IS NULL),

[Condition_Selection_1221] AS 
		(SELECT CS122.person_id, 
			CS122.condition_start_date, 
			CS122.condition_start_datetime,
			CS122.condition_end_date,
			CS122.condition_end_datetime,
			CS122.condition_type_concept_id,
			CS122.visit_occurrence_id,
			CS122.condition_source_value, 
			MAX(C.concept_id) as condition_source_concept_id
	 FROM Condition_Selection_122 CS122
	 LEFT OUTER JOIN OHDSI_KTPH.dbo.concept C
	 ON
	 	 -- ICD code is of the format 'T.D.34' then it becomes of the format 'D34' 
		-- else if it is of the format 'T.D.3412' then it becomes of the format 'D34.1' 
		-- else if it of any other format, say 'E.1234', it becomes 'E12.34'
		(CASE 
				 WHEN CS122.condition_source_value LIKE 'T._.__' 
				 THEN SUBSTRING (CS122.condition_source_value, 3, 1)
				 + SUBSTRING (CS122.condition_source_value, 5, LEN (CS122.condition_source_value) - 5) -- 5 not 4!
				 WHEN CS122.condition_source_value LIKE 'T._._%_%_' 
				 THEN  SUBSTRING (CS122.condition_source_value, 3, 1) 
				 + SUBSTRING (CS122.condition_source_value, 5, 2) 
				 +'.'
				 + SUBSTRING (CS122.condition_source_value, 7, LEN (CS122.condition_source_value) - 7) -- 7 not 6!
				 ELSE  LEFT(CS122.condition_source_value, LEN(CS122.condition_source_value) - 2)
		END = C.concept_code
	    COLLATE SQL_Latin1_General_CP1_CI_AS)
	 GROUP BY CS122.person_id, 
			CS122.condition_start_date, 
			CS122.condition_start_datetime,
			CS122.condition_end_date,
			CS122.condition_end_datetime,
			CS122.condition_type_concept_id,
			CS122.visit_occurrence_id,
			CS122.condition_source_value
	),

[Condition_Selection_12211] AS  
	(SELECT CS1221.person_id,
			CR.concept_id_2 as condition_concept_id, 
			CS1221.condition_start_date, 
			CS1221.condition_start_datetime,
			CS1221.condition_end_date,
			CS1221.condition_end_datetime,
			CS1221.condition_type_concept_id,
			CS1221.visit_occurrence_id,
			CS1221.condition_source_value, 
			CS1221.condition_source_concept_id
	FROM [Condition_Selection_1221] CS1221 
		LEFT OUTER JOIN OHDSI_KTPH.dbo.CONCEPT_RELATIONSHIP CR 
		ON  CS1221.condition_source_concept_id  = CR.concept_id_1
		AND CR.relationship_id ='Maps to'
	WHERE CS1221.condition_source_concept_id IS NOT NULL),

[Condition_Selection_1222] AS  
	(SELECT person_id, 
			condition_start_date, 
			condition_start_datetime,
			condition_end_date,
			condition_end_datetime,
			condition_type_concept_id,
			visit_occurrence_id,
			condition_source_value 
			-- condition_source_concept_id
	 FROM Condition_Selection_1221 CS1221
	 WHERE CS1221.condition_source_concept_id IS NULL
	 UNION 
	 SELECT person_id, 
			condition_start_date, 
			condition_start_datetime,
			condition_end_date,
			condition_end_datetime,
			condition_type_concept_id,
			visit_occurrence_id,
			condition_source_value 
	 FROM Condition_Selection_111 CS12211
	 WHERE CS12211.condition_concept_id IS NULL),

[Condition_Selection_12221] AS 
		(SELECT CS1222.person_id, 
			CS1222.condition_start_date, 
			CS1222.condition_start_datetime,
			CS1222.condition_end_date,
			CS1222.condition_end_datetime,
			CS1222.condition_type_concept_id,
			CS1222.visit_occurrence_id,
			CS1222.condition_source_value, 
			MAX(C.concept_id) as condition_source_concept_id
	 FROM Condition_Selection_1222 CS1222
	 LEFT OUTER JOIN OHDSI_KTPH.dbo.concept C
	 ON
		-- ICD code is of the format 'T.D.34' then it becomes of the format 'D34' 
		-- else if it is of the format 'T.D.3412' then it becomes of the format 'D34' 
		-- else if it is of any other format, say 'E12.34' or 'F45.656', it becomes 'E12' or 'F45.'
		(CASE 
				 WHEN CS1222.condition_source_value LIKE 'T._.__' 
				 THEN SUBSTRING (CS1222.condition_source_value, 3, 1)
				 + SUBSTRING (CS1222.condition_source_value, 5, LEN (CS1222.condition_source_value) - 5) -- 6 not 4!
				 WHEN CS1222.condition_source_value LIKE 'T._._%_%_' 
				 THEN  SUBSTRING (CS1222.condition_source_value, 3, 1) 
				 + SUBSTRING (CS1222.condition_source_value, 5, 2) --- map to highest level 
				 ELSE (CASE
						   WHEN  LEN(CS1222.condition_source_value) > 3 
						   THEN LEFT(CS1222.condition_source_value, LEN(CS1222.condition_source_value) - 3)
						   ELSE LEFT(CS1222.condition_source_value, LEN(CS1222.condition_source_value) - 2)
					   END)
		END = C.concept_code
	    COLLATE SQL_Latin1_General_CP1_CI_AS)
	 GROUP BY CS1222.person_id, 
			CS1222.condition_start_date, 
			CS1222.condition_start_datetime,
			CS1222.condition_end_date,
			CS1222.condition_end_datetime,
			CS1222.condition_type_concept_id,
			CS1222.visit_occurrence_id,
			CS1222.condition_source_value
	),

[Condition_Selection_122211] AS  
	(SELECT CS12221.person_id,
			CR.concept_id_2 as condition_concept_id, 
			CS12221.condition_start_date, 
			CS12221.condition_start_datetime,
			CS12221.condition_end_date,
			CS12221.condition_end_datetime,
			CS12221.condition_type_concept_id,
			CS12221.visit_occurrence_id,
			CS12221.condition_source_value, 
			CS12221.condition_source_concept_id
	FROM [Condition_Selection_12221] CS12221 
		LEFT OUTER JOIN OHDSI_KTPH.dbo.CONCEPT_RELATIONSHIP CR 
		ON  CS12221.condition_source_concept_id  = CR.concept_id_1
		AND CR.relationship_id ='Maps to'),


[Condition_Selection_12222] AS  
	(SELECT person_id, 
			condition_start_date, 
			condition_start_datetime,
			condition_end_date,
			condition_end_datetime,
			condition_type_concept_id,
			visit_occurrence_id,
			condition_source_value 
			-- condition_source_concept_id
	 FROM Condition_Selection_12221 CS12221
	 WHERE CS12221.condition_source_concept_id IS NULL
	 UNION 
	 SELECT person_id, 
			condition_start_date, 
			condition_start_datetime,
			condition_end_date,
			condition_end_datetime,
			condition_type_concept_id,
			visit_occurrence_id,
			condition_source_value 
	 FROM Condition_Selection_111 CS122211
	 WHERE CS122211.condition_concept_id IS NULL),

[Condition_Selection_122221] AS 
		(SELECT CS12222.person_id, 
			CS12222.condition_start_date, 
			CS12222.condition_start_datetime,
			CS12222.condition_end_date,
			CS12222.condition_end_datetime,
			CS12222.condition_type_concept_id,
			CS12222.visit_occurrence_id,
			CS12222.condition_source_value, 
			MAX(C.concept_id) as condition_source_concept_id
	 FROM Condition_Selection_12222 CS12222
	 LEFT OUTER JOIN OHDSI_KTPH.dbo.concept C
	 ON
	 	-- if the ICD code is of the format 'E.12345' then it becomes 'E12.345'
		-- else is stays the same 
		(CASE
		WHEN  LEN (condition_source_value) > 6 
		THEN LEFT(condition_source_value, 1) 
		     + SUBSTRING (condition_source_value,3,2)
		     +'.'
		     + SUBSTRING (condition_source_value, 5, LEN (condition_source_value) - 6)
		ELSE condition_source_value  			
		END  			   
		)= C.concept_code
	    COLLATE SQL_Latin1_General_CP1_CI_AS
	 GROUP BY CS12222.person_id, 
			CS12222.condition_start_date, 
			CS12222.condition_start_datetime,
			CS12222.condition_end_date,
			CS12222.condition_end_datetime,
			CS12222.condition_type_concept_id,
			CS12222.visit_occurrence_id,
			CS12222.condition_source_value
	),

[Condition_Selection_1222211] AS  
	(SELECT CS122221.person_id,
			CR.concept_id_2 as condition_concept_id, 
			CS122221.condition_start_date, 
			CS122221.condition_start_datetime,
			CS122221.condition_end_date,
			CS122221.condition_end_datetime,
			CS122221.condition_type_concept_id,
			CS122221.visit_occurrence_id,
			CS122221.condition_source_value, 
			CS122221.condition_source_concept_id
	FROM [Condition_Selection_122221] CS122221 
		LEFT OUTER JOIN OHDSI_KTPH.dbo.CONCEPT_RELATIONSHIP CR 
		ON  CS122221.condition_source_concept_id  = CR.concept_id_1
		AND CR.relationship_id ='Maps to')


INSERT INTO OHDSI_KTPH.dbo.condition_occurrence(person_id,
											condition_concept_id, 
											condition_start_date, 
											condition_start_datetime,
											condition_end_date,
											condition_end_datetime,
											condition_type_concept_id,
											visit_occurrence_id,
											condition_source_value, 
											condition_source_concept_id)

SELECT * FROM Condition_Selection_111 
WHERE condition_concept_id IS NOT NULL -- because sometimes a concept_id does not have a mapping on the CONCEPT RELATIONSHIP TABLE
UNION ALL
SELECT * FROM Condition_Selection_1211 
WHERE condition_concept_id IS NOT NULL -- because sometimes a concept_id does not have a mapping on the CONCEPT RELATIONSHIP TABLE
UNION ALL
SELECT * FROM Condition_Selection_12211 
WHERE condition_concept_id IS NOT NULL -- because sometimes a concept_id does not have a mapping on the CONCEPT RELATIONSHIP TABLE 
UNION ALL
SELECT * FROM Condition_Selection_122211 
WHERE condition_concept_id IS NOT NULL -- because sometimes a concept_id does not have a mapping on the CONCEPT RELATIONSHIP TABLE 
UNION ALL
SELECT * FROM Condition_Selection_1222211 
WHERE condition_concept_id IS NOT NULL -- because sometimes a concept_id does not have a mapping on the CONCEPT RELATIONSHIP TABLE 
