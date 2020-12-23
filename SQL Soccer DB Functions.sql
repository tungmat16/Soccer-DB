-- Computed columns and constraints written in SQL Server to enfore business rules in Soccer Database

CREATE FUNCTION NoInjuryInTheFuture()
RETURNS INT
AS
BEGIN
	DECLARE @RET INT = 0
	IF EXISTS (
		SELECT *
		FROM tbl_PLAYER_INJURY PLI
			JOIN tbl_PLAYER P ON PLI.player_ID = P.player_id
		WHERE PLI.begin_date > (SELECT GetDate())
	)
	BEGIN
		SET @RET = 1
	END
RETURN @RET
END
GO

ALTER TABLE tbl_PLAYER_INJURY
ADD CONSTRAINT CK_NoInjuriesInTheFuture
CHECK (dbo.NoInjuryInTheFuture() = 0)
GO


CREATE FUNCTION NoNegativeSalaries()
RETURNS INT
AS
BEGIN
	DECLARE @RET INT = 0
	IF EXISTS (
		SELECT *
		FROM tbl_PLAYER_TEAM
		WHERE salary < 0
	)
	BEGIN
		SET @RET = 1
	END
RETURN @RET
END
GO

ALTER TABLE tbl_Player_Team
ADD CONSTRAINT CK_NoNegativeSalaries
CHECK (dbo.NoNegativeSalaries() = 0)
GO


CREATE FUNCTION NoNegativeReleaseClauses()
RETURNS INT
AS
BEGIN
	DECLARE @RET INT = 0
	IF EXISTS (
	SELECT *
	FROM tbl_PLAYER_TEAM
	WHERE release_clause_value < 0
	)
	BEGIN
		SET @RET = 1
	END
RETURN @RET
END
GO

ALTER TABLE tbl_Player_Team
ADD CONSTRAINT CK_NoNegativeReleaseClauses
CHECK (dbo.NoNegativeReleaseClauses() = 0)
GO


CREATE FUNCTION TotalGoalsScoredCareer(@PK INT)
RETURNS numeric(12,2)
AS
BEGIN
	DECLARE @RET numeric(12,2) = 
		(SELECT sum(PMS.[value])
		FROM tbl_PLAYER_MATCH_STAT PMS
			JOIN tbl_STAT S ON PMS.stat_id = S.stat_id
			JOIN tbl_PLAYER P ON PMS.player_id = P.player_id
			JOIN tbl_STAT_TYPE ST ON S.stat_type_id = ST.stat_type_id
		WHERE P.player_id = @PK 
			AND ST.stat_type_name = 'Goals Scored'
		)
RETURN @RET
END
GO

ALTER TABLE tbl_PLAYER
ADD CareerGoalsScored AS (dbo.TotalGoalsScoredCareer(player_id))
GO

CREATE FUNCTION TotalSalaries(@PK INT)
RETURNS numeric(12,2)
AS
BEGIN
	DECLARE @RET numeric(12,2) = 
		(SELECT SUM(PT.salary)
		FROM tbl_PLAYER_TEAM PT
			JOIN tbl_TEAM T ON PT.team_id = T.team_id
		WHERE T.team_id = @PK
			AND PT.start_date <= (SELECT GetDate())
			AND PT.end_date > (SELECT GetDate())
		)
RETURN @RET
END
GO

ALTER TABLE tbl_TEAM
ADD TeamSalary_ActiveContracts AS (dbo.TotalSalaries(team_id))
GO


