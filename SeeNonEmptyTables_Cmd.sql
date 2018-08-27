/*To see the names of all tables that are NOT empty
*/
Exec sp_MSforeachtable 'IF EXISTS (SELECT 1 FROM ?) PRINT ''?'' '
