CREATE TABLE OHDSI_KTPH.dbo.visit_id_source_mapping ( 
/* This table is not part of the OMOP CDM */ 
/* This table serves to link visit_occurence_id (the primary key of visit occurence) */ 
/* to encounter_id and pat_type_cd (the primary key of t_encounter) */ 
	encounter_id VARCHAR(100),
	pat_type_cd VARCHAR (100), 
	visit_occurrence_id INTEGER IDENTITY(0,1) PRIMARY KEY) ;  