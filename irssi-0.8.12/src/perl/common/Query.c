/*
 * This file was generated automatically by xsubpp version 1.9508 from the
 * contents of Query.xs. Do not edit this file, edit Query.xs instead.
 *
 *	ANY CHANGES MADE HERE WILL BE LOST!
 *
 */

#line 1 "Query.xs"
#include "module.h"

#line 13 "Query.c"

XS(XS_Irssi_queries); /* prototype to pass -Wmissing-prototypes */
XS(XS_Irssi_queries)
{
    dXSARGS;
    if (items != 0)
	Perl_croak(aTHX_ "Usage: Irssi::queries()");
   PERL_UNUSED_VAR(ax); /* -Wall */
    SP -= items;
    {
#line 9 "Query.xs"
	GSList *tmp;
#line 26 "Query.c"
#line 11 "Query.xs"
	for (tmp = queries; tmp != NULL; tmp = tmp->next) {
		QUERY_REC *rec = tmp->data;

		XPUSHs(sv_2mortal(iobject_bless(rec)));
	}
#line 33 "Query.c"
	PUTBACK;
	return;
    }
}


XS(XS_Irssi_query_find); /* prototype to pass -Wmissing-prototypes */
XS(XS_Irssi_query_find)
{
    dXSARGS;
    if (items != 1)
	Perl_croak(aTHX_ "Usage: Irssi::query_find(nick)");
    {
	char *	nick = (char *)SvPV_nolen(ST(0));
	Irssi__Query	RETVAL;
#line 21 "Query.xs"
	RETVAL = query_find(NULL, nick);
#line 51 "Query.c"
	ST(0) = iobject_bless((SERVER_REC *)RETVAL);

	sv_2mortal(ST(0));
    }
    XSRETURN(1);
}


XS(XS_Irssi__Server_queries); /* prototype to pass -Wmissing-prototypes */
XS(XS_Irssi__Server_queries)
{
    dXSARGS;
    if (items != 1)
	Perl_croak(aTHX_ "Usage: Irssi::Server::queries(server)");
    SP -= items;
    {
	Irssi__Server	server = irssi_ref_object(ST(0));
#line 33 "Query.xs"
	GSList *tmp;
#line 71 "Query.c"
#line 35 "Query.xs"
	for (tmp = server->queries; tmp != NULL; tmp = tmp->next) {
		QUERY_REC *rec = tmp->data;

		XPUSHs(sv_2mortal(iobject_bless(rec)));
	}
#line 78 "Query.c"
	PUTBACK;
	return;
    }
}


XS(XS_Irssi__Server_query_find); /* prototype to pass -Wmissing-prototypes */
XS(XS_Irssi__Server_query_find)
{
    dXSARGS;
    if (items != 2)
	Perl_croak(aTHX_ "Usage: Irssi::Server::query_find(server, nick)");
    {
	Irssi__Server	server = irssi_ref_object(ST(0));
	char *	nick = (char *)SvPV_nolen(ST(1));
	Irssi__Query	RETVAL;

	RETVAL = query_find(server, nick);
	ST(0) = iobject_bless((SERVER_REC *)RETVAL);

	sv_2mortal(ST(0));
    }
    XSRETURN(1);
}


XS(XS_Irssi__Query_destroy); /* prototype to pass -Wmissing-prototypes */
XS(XS_Irssi__Query_destroy)
{
    dXSARGS;
    if (items != 1)
	Perl_croak(aTHX_ "Usage: Irssi::Query::destroy(query)");
    {
	Irssi__Query	query = irssi_ref_object(ST(0));

	query_destroy(query);
    }
    XSRETURN_EMPTY;
}


XS(XS_Irssi__Query_change_server); /* prototype to pass -Wmissing-prototypes */
XS(XS_Irssi__Query_change_server)
{
    dXSARGS;
    if (items != 2)
	Perl_croak(aTHX_ "Usage: Irssi::Query::change_server(query, server)");
    {
	Irssi__Query	query = irssi_ref_object(ST(0));
	Irssi__Server	server = irssi_ref_object(ST(1));

	query_change_server(query, server);
    }
    XSRETURN_EMPTY;
}

#ifdef __cplusplus
extern "C"
#endif
XS(boot_Irssi__Query); /* prototype to pass -Wmissing-prototypes */
XS(boot_Irssi__Query)
{
    dXSARGS;
    char* file = __FILE__;

    XS_VERSION_BOOTCHECK ;

        newXSproto("Irssi::queries", XS_Irssi_queries, file, "");
        newXSproto("Irssi::query_find", XS_Irssi_query_find, file, "$");
        newXSproto("Irssi::Server::queries", XS_Irssi__Server_queries, file, "$");
        newXSproto("Irssi::Server::query_find", XS_Irssi__Server_query_find, file, "$$");
        newXSproto("Irssi::Query::destroy", XS_Irssi__Query_destroy, file, "$");
        newXSproto("Irssi::Query::change_server", XS_Irssi__Query_change_server, file, "$$");
    XSRETURN_YES;
}

