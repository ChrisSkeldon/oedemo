/*------------------------------------------------------------------------
  File        : ttAppUser.i
  Purpose     : Contains details of application users.

  Syntax      :

  Description :

  Author(s)   :
  Created     : Mon Apr 11 12:49:36 BST 2016
  Notes       :
  ----------------------------------------------------------------------*/

DEFINE {&SCOPE} TEMP-TABLE ttAppUser{&SUFFIX} NO-UNDO {&REFERENCE-ONLY}
  BEFORE-TABLE ttAppUserBefore{&SUFFIX}
  FIELD AppUserid  AS CHARACTER FORMAT "x(12)"
  FIELD Password   AS CHARACTER FORMAT "x(16)"
  FIELD DomainName AS CHARACTER FORMAT "x(64)" LABEL "Domain Name"
  FIELD FirstName  AS CHARACTER FORMAT "x(25)" LABEL "First Name"
  FIELD Surname    AS CHARACTER FORMAT "x(25)"
  FIELD Email      AS CHARACTER FORMAT "x(50)"
  FIELD UserNumber AS INTEGER                  LABEL "User Number"
  FIELD UserRoles  AS CHARACTER FORMAT "x(25)" LABEL "User Roles"
  FIELD IsDisabled AS LOGICAL                  LABEL "Account Disabled"
  FIELD IsExpired  AS LOGICAL                  LABEL "Account Expired"
  FIELD IsLocked   AS LOGICAL                  LABEL "Account Locked"
  {com/progress/demo/datadef/StandardTTFields.i}
  INDEX uIdxSortNum IS PRIMARY IS UNIQUE SortNum.
