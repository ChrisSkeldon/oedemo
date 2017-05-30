/*------------------------------------------------------------------------
  File        : IAppUserProvider
  Purpose     : Interface that should be implemented by classes that are
                going to provide data to HybridRealm
  Syntax      :
  Description :
  Author(s)   : Chris
  Created     :
  Notes       :
  ----------------------------------------------------------------------*/

INTERFACE com.progress.demo.security.IAppUserProvider:

  /*------------------------------------------------------------------------------
   Purpose: Return the value for a attribute associated with a user.

   Notes: If the user identifier passed in does not identify a user an
          AppError is thrown.

   @param piUserNumber Unique identifier for a user
   @param pcAttributeName Name of the attribute to return a value for.
   @return Value of the attribute or, if the attribute is not found, an empty
           string.
  ------------------------------------------------------------------------------*/
  METHOD PUBLIC CHARACTER FetchAttribute( INPUT piUserNumber AS INTEGER,
                                          INPUT pcAttributeName AS CHARACTER ).


  /*------------------------------------------------------------------------------
   Purpose: Is passed in a user's login name and returns the unique integer
            identifier for that user.
   Notes:
   @param User's login name.
   @return The unique identifier for a user or -1 if the login name does not
           match a current user.
  ------------------------------------------------------------------------------*/
  METHOD PUBLIC INTEGER FetchUserNumber( INPUT pcLoginName AS CHARACTER ).


  /*------------------------------------------------------------------------------
   Purpose: Is passed the unique identifier for a user and a related password.
            Verifies that the password passed in is correct for that user.

   Notes: If the user identifier passed in does not identify a user an AppError
          is thrown.

   @param piUserNumber Unique identifier for a user.
   @param pcUserPassword User's password.
   @return TRUE if the user's password is valid and FALSE otherwise.
  ------------------------------------------------------------------------------*/
  METHOD PUBLIC LOGICAL IsPasswordValid( INPUT piUserNumber AS INTEGER,
                                         INPUT pcUserPassword AS CHARACTER ).

  /*------------------------------------------------------------------------------
   Purpose: Set the password for a user.
   Notes:
   @param piUserNumber Unique identifier for a user.
   @param pcUserPassword User's new password.
   @return TRUE if the user's password is set and FALSE otherwise.
  ------------------------------------------------------------------------------*/
  METHOD PUBLIC LOGICAL SetPassword( INPUT piUserNumber AS INTEGER,
                                     INPUT pcUserPassword AS CHARACTER ).

  /*------------------------------------------------------------------------------
   Purpose: Sets where this class should get its users from.

   Notes: If users are loaded from a file, file must be in json format and
          on the PROPATH.

   @param pcUserSource Should be 'db' if the users are stored on the database or
          the name of the file to load users from.
   @return Number of users loaded from file or found in the database.
  ------------------------------------------------------------------------------*/
  METHOD PUBLIC INT64 SetUserSource( INPUT pcUserSource AS CHARACTER ).

END INTERFACE.