/*------------------------------------------------------------------------
  File        : Properties
  Purpose     :

  Syntax      :

  Description : Simple property manager for security featues.

  Author(s)   : davec
  Created     : Mon Apr 08 10:27:32 EDT 2013
  Notes       :
 ----------------------------------------------------------------------*/

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS com.progress.demo.security.Properties:

  DEFINE PRIVATE STATIC VARIABLE debugMsg AS LOGICAL NO-UNDO INITIAL TRUE.

  DEFINE PRIVATE STREAM m_propStream.

  DEFINE PRIVATE TEMP-TABLE m_properties NO-UNDO
    FIELD propName  AS CHARACTER
    FIELD propValue AS CHARACTER
    INDEX idxName IS UNIQUE PRIMARY propName.


  /*------------------------------------------------------------------------------
   Purpose:
   Notes:
  ------------------------------------------------------------------------------*/
  CONSTRUCTOR PUBLIC Properties (  ):

    SUPER ().

  END CONSTRUCTOR.


  /*------------------------------------------------------------------------------
   Purpose:
   Notes:
  ------------------------------------------------------------------------------*/
  CONSTRUCTOR PUBLIC Properties ( INPUT p_path AS CHARACTER ):

    SUPER ().

    IF ( ? = p_path OR "" = p_path ) THEN

      UNDO, THROW NEW Progress.Lang.AppError("Invalid properties file path", 1).

    LoadProps(p_path).

  END CONSTRUCTOR.


  /*------------------------------------------------------------------------------
   Purpose:
   Notes:
  ------------------------------------------------------------------------------*/
  METHOD PUBLIC CHARACTER GetCharacterProperty( INPUT p_propName AS CHARACTER, INPUT p_defValue AS CHARACTER ):

    DEFINE VARIABLE result AS CHARACTER NO-UNDO.


    IF ( ? = p_propName OR "" = p_propName ) THEN
    DO:
      UNDO, THROW NEW Progress.Lang.AppError("Invalid parameters", 2).
    END.


    FIND FIRST m_properties WHERE m_properties.propName = p_propName NO-ERROR.

    IF ( AVAILABLE m_properties ) THEN

      result = m_properties.propValue.

    ELSE
    DO:

      IF ( ? = p_defValue  ) THEN
      DO:
        UNDO, THROW NEW Progress.Lang.AppError("Invalid parameters", 3).
      END.

      result = p_defValue.
    END.

    RETURN result.

  END METHOD.


  /*------------------------------------------------------------------------------
   Purpose:
   Notes:
  ------------------------------------------------------------------------------*/
  METHOD PUBLIC LOGICAL GetLogicalProperty( INPUT p_propName AS CHARACTER, 
                                            INPUT p_defValue AS LOGICAL ):

    DEFINE VARIABLE result  AS LOGICAL   INITIAL NO NO-UNDO.
    DEFINE VARIABLE convert AS LOGICAL   INITIAL NO NO-UNDO.
    DEFINE VARIABLE tmp     AS CHARACTER INITIAL "" NO-UNDO.


    IF ( ? = p_propName OR "" = p_propName ) THEN
    DO:
      UNDO, THROW NEW Progress.Lang.AppError("Invalid parameters", 4).
    END.


    FIND FIRST m_properties WHERE propName = p_propName NO-ERROR.

    IF ( AVAILABLE m_properties AND "" <> m_properties.propValue ) THEN
    DO:
      tmp = LC(m_properties.propValue).
    END.


    IF ( "" = tmp ) THEN
    DO:

      IF ( ? = p_defValue  ) THEN
      DO:
        UNDO, THROW NEW Progress.Lang.AppError("Invalid parameters",5).
      END.

      result = p_defValue.
    END.
    ELSE
    DO:

      IF ( tmp BEGINS "t" OR

        tmp BEGINS "y" OR

        tmp BEGINS "1" ) THEN

        result = YES.

    END.

    RETURN result.

  END METHOD.


  /*------------------------------------------------------------------------------
   Purpose:
   Notes:
  ------------------------------------------------------------------------------*/
  METHOD PROTECTED LOGICAL LoadProps ( INPUT p_path AS CHARACTER  ):

    DEFINE VARIABLE retVal       AS LOGICAL   NO-UNDO INITIAL FALSE.
    DEFINE VARIABLE propFilePath AS CHARACTER NO-UNDO.

    IF debugMsg THEN
    DO:
      MESSAGE "Loading properties from file:" p_path.
    END.

    propFilePath = SEARCH(p_path).

    IF ( ? <> propFilePath ) THEN
    DO:
      IF debugMsg THEN
      DO:
        MESSAGE "Opening properties file:" propFilePath.
      END.

      INPUT STREAM m_propStream FROM VALUE(propFilePath).

      IF debugMsg THEN
      DO:
        MESSAGE "Loading properties file:" propFilePath.
      END.

      REPEAT :

        CREATE m_properties.

        IMPORT STREAM m_propStream DELIMITER "=" m_properties NO-ERROR.

      END.

      INPUT STREAM m_propStream CLOSE.

      FOR EACH m_properties :

        IF debugMsg THEN
        DO:
          MESSAGE "Loaded property" m_properties.propName "with value:" m_properties.propValue.
        END.
      END.

      retVal = TRUE.

    END.
    ELSE
    DO:

      IF debugMsg THEN
      DO:
        MESSAGE "No properties file to load:" p_path.
      END.
    END.


    RETURN retVal.

    CATCH e AS Progress.Lang.Error:
      MESSAGE "Error in properties load: " e:GetMessage(1).
    END CATCH.

    FINALLY:
      INPUT STREAM m_propStream CLOSE.
    END FINALLY.

  END METHOD.

END CLASS.