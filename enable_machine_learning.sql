


--The Machine Learning Services feature can be enabled by running the following command:

EXEC sp_configure 'external scripts enabled', 1;
RECONFIGURE WITH OVERRIDE;



---error when enabling machine learning below

--Msg 39020, Level 16, State 1, Procedure sp_configure, Line 177 [Batch Start Line 0]
--Feature 'Advanced Analytics Extensions' is not installed. Please consult Books Online for more information on this feature.

--#########################################SOLUTION
