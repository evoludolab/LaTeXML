/*
       # / == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == = \ #
       # |  LaTeXML.xs                                                         | #
       # |                                                                     | #
       # |=====================================================================| #
       # | Part of LaTeXML:                                                    | #
       # |  Public domain software, produced as part of work done by the       | #
       # |  United States Government & not subject to copyright in the US.     | #
       # |---------------------------------------------------------------------| #
       # | Bruce Miller <bruce.miller@nist.gov>                        #_#     | #
       # | http://dlmf.nist.gov/LaTeXML/                              (o o)    | #
       # \=========================================================ooo==U==ooo=/ #
  */

#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"
  /* Perhaps we should be using SV * ?  We're losing the unicode setting of the string! */
  /* Also: currently we copy string & free on DESTROY; Do getString (etal) need to copy? */
  /* the C ends up with sv_setpv, which(apparently) copies the string into the PV(string var) */
typedef char * UTF8;
typedef struct Token {
  int catcode;
  UTF8 string;
} T_Token;

typedef T_Token * PTR_Token;


typedef struct Token * LaTeXML_Core_Token;
typedef AV * LaTeXML_Core_Tokens;

typedef enum {
    CC_ESCAPE      =  0,
    CC_BEGIN       =  1,
    CC_END         =  2,
    CC_MATH        =  3,
    CC_ALIGN       =  4,
    CC_EOL         =  5,
    CC_PARAM       =  6,
    CC_SUPER       =  7,
    CC_SUB         =  8,
    CC_IGNORE      =  9,
    CC_SPACE       = 10,
    CC_LETTER      = 11,
    CC_OTHER       = 12,
    CC_ACTIVE      = 13,
    CC_COMMENT     = 14,
    CC_INVALID     = 15,
    CC_CS          = 16,
    CC_NOTEXPANDED = 17,
    CC_MARKER      = 18
} T_Catcode;

/* Categorization of Category codes */

int PRIMITIVE_CATCODE[] = 
  { 1, 1, 1, 1,
    1, 1, 1, 1,
    1, 0, 1, 0,
    0, 0, 0, 0,
    0, 1};
int EXECUTABLE_CATCODE[] =
  { 0, 1, 1, 1,
    1, 0, 0, 1,
    1, 0, 0, 0,
    0, 1, 0, 0,
    1, 0};

int ACTIVE_OR_CS[] = 
  {0, 0, 0, 0,
   0, 0, 0, 0,
   0, 0, 0, 0,
   0, 1, 0, 0,
   1, 0};
int LETTER_OR_OTHER[] = 
  {0, 0, 0, 0,
   0, 0, 0, 0,
   0, 0, 0, 1,
   1, 0, 0, 0,
   0, 0};

UTF8 standardchar[] =
  { "\\",  "{",   "}",   "$",
    "&",  "\n",  "#",  "^",
    "_",  NULL, NULL, NULL,
    NULL, NULL, "%",  NULL};

UTF8 CC_NAME[] =
  {"Escape", "Begin", "End", "Math",
   "Align", "EOL", "Parameter", "Superscript",
   "Subscript", "Ignore", "Space", "Letter",
   "Other", "Active", "Comment", "Invalid",
   "ControlSequence", "NotExpanded"};
UTF8 PRIMITIVE_NAME[] =
  {"Escape",    "Begin", "End",       "Math",
   "Align",     "EOL",   "Parameter", "Superscript",
   "Subscript", NULL,    "Space",     NULL,
   NULL,        NULL,     NULL,       NULL,
   NULL,       "NotExpanded"};
UTF8 EXECUTABLE_NAME[] = 
  {NULL,       "Begin", "End", "Math",
   "Align",     NULL,   NULL, "Superscript",
   "Subscript", NULL,   NULL, NULL,
   NULL,        NULL,   NULL, NULL,
   NULL,        NULL};

UTF8 CC_SHORT_NAME[] =
  {"T_ESCAPE", "T_BEGIN", "T_END", "T_MATH",
   "T_ALIGN", "T_EOL", "T_PARAM", "T_SUPER",
   "T_SUB", "T_IGNORE", "T_SPACE", "T_LETTER",
   "T_OTHER", "T_ACTIVE", "T_COMMENT", "T_INVALID",
   "T_CS", "T_NOTEXPANDED"};

LaTeXML_Core_Token
make_token(UTF8 string, int catcode){
  /* check 0 <= catcode <= 18 !!!*/
  /*check string not null ? */
  /*PTR_Token token = malloc(sizeof(T_Token));*/
  PTR_Token token;
  Newx(token,1,T_Token);
  /* check for out of memory ? */
  /*token->string = (UTF8) malloc((strlen(string) + 1) * sizeof(char));*/
  Newx(token->string,(strlen(string) + 1),char);
  strcpy(token->string, string);
  token->catcode = catcode;
  return token; }

#define SvToken(arg) INT2PTR(LaTeXML_Core_Token, SvIV((SV*)SvRV(arg)))

#define T_LETTER(arg) (make_token((arg), 11))
#define T_OTHER(arg)  (make_token((arg), 12))
#define T_ACTIVE(arg) (make_token((arg), 13))
#define T_CS(arg)     (make_token((arg), 16))

MODULE = LaTeXML PACKAGE = LaTeXML::Core::Token

LaTeXML_Core_Token
Token(string, catcode)
  UTF8 string
  int catcode
  CODE:
  RETVAL = make_token(string, catcode);
  OUTPUT:
  RETVAL

LaTeXML_Core_Token
T_LETTER(string)
  UTF8 string

LaTeXML_Core_Token
T_OTHER(string)
  UTF8 string

LaTeXML_Core_Token
T_ACTIVE(string)
  UTF8 string

LaTeXML_Core_Token
T_CS(string)
  UTF8 string

int
getCatcode(self)
  LaTeXML_Core_Token self
  CODE:
  RETVAL = self->catcode;
  OUTPUT:
  RETVAL

UTF8
getString(self)
  LaTeXML_Core_Token self
  CODE:
  RETVAL = self->string;
  OUTPUT:
  RETVAL

UTF8
toString(self)
  LaTeXML_Core_Token self
  CODE:
  RETVAL = self->string;
  OUTPUT:
  RETVAL

int
getCharcode(self)
  LaTeXML_Core_Token self
  CODE:
  RETVAL = (self->catcode == CC_CS ? 256 : (int) self->string [0]);
  OUTPUT:
  RETVAL

UTF8
getCSName(self)
  LaTeXML_Core_Token self
  INIT:
  UTF8 s = PRIMITIVE_NAME[self->catcode];
  CODE:
   RETVAL = (s == NULL ? self->string : s);
   OUTPUT:
   RETVAL 

UTF8
getMeaningName(self)
  LaTeXML_Core_Token self
  CODE:
  RETVAL = (ACTIVE_OR_CS[self->catcode]
              ? self->string
              : NULL);
  OUTPUT:
  RETVAL

UTF8
getExpandableName(self)
  LaTeXML_Core_Token self
  CODE:
  RETVAL = (ACTIVE_OR_CS [self->catcode]
    ? self->string
              : EXECUTABLE_NAME[self->catcode]);
  OUTPUT:
  RETVAL 

# Not used?
UTF8
getExecutableName(self)
    LaTeXML_Core_Token self
    INIT:
    UTF8 s = PRIMITIVE_NAME[self->catcode];
    CODE:
    RETVAL = (EXECUTABLE_CATCODE[self->catcode]
              ? (s == NULL ? self->string : s)
                 : NULL);
    OUTPUT:
    RETVAL 

int
isExecutable(self)
    LaTeXML_Core_Token self
    CODE:
    RETVAL = EXECUTABLE_CATCODE [self->catcode];
    OUTPUT:
    RETVAL

    #    /* Compare two tokens; They are equal if they both have same catcode & string*/
    #    /* [We pretend all SPACE's are the same, since we'd like to hide newline's in there!]*/
    #    /* NOTE: That another popular equality checks whether the "meaning" (defn) are the same.*/
    #    /* That is NOT done here; see Equals(x,y) and XEquals(x,y)*/

int
equals(self, b)
    LaTeXML_Core_Token self
    SV * b
    INIT:
    IV bptr;
    LaTeXML_Core_Token bb;
    CODE:
    if (SvOK(b) && sv_isa(b, "LaTeXML::Core::Token")) {
    bptr = SvIV((SV *) SvRV(b));
    bb = INT2PTR(LaTeXML_Core_Token, bptr);
    if (self->catcode != bb->catcode) {
      RETVAL = 0; }
    else if (self->catcode == CC_SPACE) {
      RETVAL = 1; }
    else {
      RETVAL = strcmp(self->string, bb->string) == 0; } }
  else {
    RETVAL = 0; }
   OUTPUT:
    RETVAL

void
DESTROY(self)
    LaTeXML_Core_Token self
    CODE:
    # printf("DESTROY TOKEN %s[%s]!\n",CC_SHORT_NAME[self->catcode],self->string);
    # free(self->string);
    # free(self);
    Safefree(self->string);
    Safefree(self);

MODULE = LaTeXML PACKAGE = LaTeXML::Core::Tokens

  #  Return a LaTeXML::Core::Tokens made from the arguments (tokens)
  # Curiously, faster but more resident memory?
  #   av_extend doesn't help; is newRV *always* required?
  # Potential optimizations:
  #   - empty args: return a constant
  #   - single Tokens arg; just return that arg
  #   - do our own memory management of the array of Token's

LaTeXML_Core_Tokens
Tokens(...)
  INIT:
    int i;
    AV * tokens = newAV();
  CODE:
  /* Use av_extend to pre-size the thing?*/
  /* fprintf(stderr, "\nCreate Tokens(%d): ", items);*/
  /* av_extend(tokens, items); */
  for (i = 0 ; i < items ; i++) {
    /*fprintf(stderr, "Item %d; ", sv_isobject(ST(i)));*/
    SV * t = ST(i);
    if (sv_isa(t, "LaTeXML::Core::Token")) {
      /*if (strcmp(sv_reftype(t, 1),"LaTeXML::Core::Token") == 0) {*/
      /*fprintf(stderr, "Token %d.",SvTYPE(t));*/
      av_push(tokens, newRV_inc((SV *) SvRV(t))); }
    else if (sv_isa(t, "LaTeXML::Core::Tokens")) {
      /*else if(strcmp(sv_reftype(t, 1),"LaTeXML::Core::Tokens") == 0) {*/
      AV * ts = (AV *)SvRV(t);
      int nt = av_top_index(ts);
      int j;
      /* fprintf(stderr, "Tokens(%d): ", nt+1);*/
      for (j = 0 ; j <= nt ; j++) {
        SV * tt = * (SV * *) av_fetch(ts, j, 0);
        /* fprintf(stderr, "adding item %d: %s; ",j, sv_reftype(tt, 1));*/
        av_push(tokens, (SV *) tt); } } /* Already a ref */
    else {
      /* Fatal('misdefined', $r, undef, "Expected a Token, got " . Stringify($_))*/
      croak("Tokens: Expected a Token, got ???"); }
  }
  /*fprintf(stderr, "done\n"); */
  /*sv_2mortal((SV *) tokens);*/
  RETVAL = tokens;
  OUTPUT:
  RETVAL

LaTeXML_Core_Tokens
store__Tokens(...)
  INIT:
    int i;
    AV * tokens = newAV();
    int n = items;
    int p = 0;
  CODE:
  /* Use av_extend to pre-size the thing?*/
  /* fprintf(stderr, "\nCreate Tokens(%d): ", items);*/
  av_extend(tokens, n);
  for (i = 0 ; i < items ; i++) {
    SV * t = SvRV(ST(i));
    /* fprintf(stderr, "Item %s; ", sv_reftype(t, 1));*/
    /* if (sv_isa(t, "LaTeXML::Core::Token")) {*/
    if (strcmp(sv_reftype(t, 1),"LaTeXML::Core::Token") == 0) {
      /*fprintf(stderr, "Token %d.",SvTYPE(t));*/
      av_store(tokens, p++, newRV_inc((SV *) t)); }
    /*else if (sv_isa(t, "LaTeXML::Core::Tokens")) {*/
    else if(strcmp(sv_reftype(t, 1),"LaTeXML::Core::Tokens") == 0) {
      int nt = av_top_index((AV *)t);
      int j;
      n += nt - 1;
      av_extend(tokens, n);
      /* fprintf(stderr, "Tokens(%d): ", nt+1);*/
      for (j = 0 ; j <= nt ; j++) {
        SV * tt = * (SV * *) av_fetch((AV *)t, j, 0);
        /* fprintf(stderr, "adding item %d: %s; ",j, sv_reftype(tt, 1));*/
        av_store(tokens, p++, (SV *) tt); } } /* Already a ref */
    else {
      /* Fatal('misdefined', $r, undef, "Expected a Token, got " . Stringify($_))*/
      croak("Tokens: Expected a Token, got ???"); }
  }
  /*fprintf(stderr, "done\n"); */
  RETVAL = tokens;
  OUTPUT:
  RETVAL

LaTeXML_Core_Tokens
ZZZZZZTokens(...)
  INIT:
    int i;
    AV * tokens = newAV();
  CODE:
  /* Use av_extend to pre-size the thing?*/
  /* fprintf(stderr, "\nCreate Tokens(%d): ", items);*/
  /*av_extend(tokens, items);*/
  for (i = 0 ; i < items ; i++) {
    /*SV * t = SvRV(ST(i));*/
    SV * t = ST(i);
    /* fprintf(stderr, "Item %s; ", sv_reftype(t, 1));*/
    if (sv_isa(t, "LaTeXML::Core::Token")) {
       fprintf(stderr, "Token.%d",SvTYPE(t));
      if(SvTYPE(t) == SVt_IV){
        SvREFCNT_inc(t);
        av_push(tokens, (SV *) t); }
      else {
        av_push(tokens, newRV_inc((SV *) t)); } }
    else if (sv_isa(t, "LaTeXML::Core::Tokens")) {
      t = SvRV(t);
      int nt = av_top_index((AV *)t);
      int j;
      /* fprintf(stderr, "Tokens(%d): ", nt+1);*/
      for (j = 0 ; j <= nt ; j++) {
        SV * tt = * (SV * *) av_fetch((AV *)t, j, 0);
        /* fprintf(stderr, "adding item %d: %s; ",j, sv_reftype(tt, 1));*/
        av_push(tokens, (SV *) tt); } } /* Already a ref */
    else {
      /* Fatal('misdefined', $r, undef, "Expected a Token, got " . Stringify($_))*/
      croak("Tokens: Expected a Token, got ???"); }
  }
  /*fprintf(stderr, "done\n"); */
  RETVAL = tokens;
  OUTPUT:
  RETVAL

int
isBalanced(self)
  LaTeXML_Core_Tokens self
  INIT:
   int i, n, level;
  CODE:
    n = av_top_index(self);
    level = 0;
  /*fprintf(stderr,"\nChecking balance of %d tokens",n);*/
  for (i = 0 ; i <= n ; i++) {
    LaTeXML_Core_Token t = SvToken(* (SV * *) av_fetch(self, i, 0));
    int cc = t->catcode;
    /*fprintf(stderr,"[%d]",cc);*/
    if (cc == CC_BEGIN) {
      /*fprintf(stderr,"+");*/
      level++; }
    else if (cc == CC_END) {
      /*fprintf(stderr,"-");*/
      level--; } }
  /*fprintf(stderr,"net %d",level);*/
  RETVAL = (level == 0);
  OUTPUT:
  RETVAL

LaTeXML_Core_Tokens
substituteParameters(self,...)
  LaTeXML_Core_Tokens self
  INIT:
    int i,n;
    AV * tokens = newAV();
  CODE:
  /*fprintf(stderr,"\nsubstituting:");*/
    n = av_top_index(self);
    for(i = 0 ; i <= n; i++){
      SV * tv = * (SV * *) av_fetch(self, i, 0);
      LaTeXML_Core_Token t = SvToken(tv);
      int cc = t->catcode;
      if(cc != CC_PARAM){ /* non #, so copy it*/
        /*fprintf(stderr,"copy;");*/
        av_push(tokens,tv); }
      else if(i == n) {
        croak("substituteParamters: fell off end of pattern"); }
      else {
        /*fprintf(stderr,"#");*/
        tv = * (SV * *) av_fetch(self, ++i, 0);
        t = SvToken(tv);
        cc = t->catcode;
        if(cc == CC_PARAM){ /* next char is #, just insert it */
          /*fprintf(stderr,"copy;");*/
          av_push(tokens,tv); }
        else {                  /* otherwise, insert the appropriate arg. */
          int argn = (int) t->string[0] - (int) '0';
          /*fprintf(stderr,"arg%d;",argn);*/
          if((argn < 1) || (argn > 9)){
            croak("substituteTokens: Illegal argument number %d",argn); }
          else if ((argn <= items) && SvOK(ST(argn))){      /* ignore undef */
            SV * t = SvRV(ST(argn));
            if (strcmp(sv_reftype(t, 1),"LaTeXML::Core::Token") == 0) {
              av_push(tokens, newRV_inc((SV *) t)); }
            else if(strcmp(sv_reftype(t, 1),"LaTeXML::Core::Tokens") == 0) {
              int nt = av_top_index((AV *)t);
              int j;
              for (j = 0 ; j <= nt ; j++) {
                SV * tt = * (SV * *) av_fetch((AV *)t, j, 0);
                av_push(tokens, (SV *) tt); } }/* Already a ref */
            else {
              /* Probably should be trying to Revert(arg) here! */
              /* Fatal('misdefined', $r, undef, "Expected a Token, got " . Stringify($_))*/
              croak("substituteTokens: Expected a Token or Tokens, got ???"); } } }
        } }
  /*fprintf(stderr,"done\n");*/
  RETVAL = tokens;
  OUTPUT:
  RETVAL
