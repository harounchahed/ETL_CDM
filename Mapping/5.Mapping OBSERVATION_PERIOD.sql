-- the observation period is the difference in time 
-- between the first visit_occurrence of a certain patient 
-- and his/her last visit_occurrence.
INSERT INTO OHDSI_KTPH.dbo.observation_period
SELECT VO.person_id AS person_id, 
	   MIN(VO.visit_start_date) as observation_period_start_date,
	   MAX(VO.visit_end_date) as observation_period_end_date,
	   38000280 as period_type_concept_id --Observation recorded from EHR
FROM OHDSI_KTPH.dbo.visit_occurrence VO 
GROUP BY VO.person_id 