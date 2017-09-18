/******************************************************************************
* Exception : LIB$DDL_Exception
*                                                                            
* Date    : 2017-09-18
* Author  : Slavomir Skopalik
* Server  : Firebird 2.5.7
* Purpose : General exception for database DDL operation  
*                                                                               
* Revision History                                                           
* ================                                                           
*                                                                            
*                                                                            
******************************************************************************/

CREATE OR ALTER EXCEPTION LIB$DDL_Exception 'DDL operation is not possible';
