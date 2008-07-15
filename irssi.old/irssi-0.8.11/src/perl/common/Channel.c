/*
 * This file was generated automatically by xsubpp version 1.9508 from the
 * contents of Channel.xs. Do not edit this file, edit Channel.xs instead.
 *
 *	ANY CHANGES MADE HERE WILL BE LOST!
 *
 */

#line 1 "Channel.xs"
#include "module.h"

#line 13 "Channel.c"
XS(XS_Irssi_channels); /* prototype to pass -Wmissing-prototypes */
XS(XS_Irssi_channels)
{
    dXSARGS;
    if (items != 0)
	Perl_croak(aTHX_ "Usage: Irssi::channels()");
   PERL_UNUSED_VAR(ax); /* -Wall */
    SP -= items;
    {
#line 9 "Channel.xs"
	GSList *tmp;
#line 25 "Channel.c"
#line 11 "Channel.xs"
	for (tmp = channels; tmp != NULL; tmp = tmp->next) {
		XPUSHs(sv_2mortal(iobject_bless((CHANNEL_REC *) tmp->data)));
	}
#line 30 "Channel.c"
	PUTBACK;
	return;
    }
}

XS(XS_Irssi_channel_find); /* prototype to pass -Wmissing-prototypes */
XS(XS_Irssi_channel_find)
{
    dXSARGS;
    if (items != 1)
	Perl_croak(aTHX_ "Usage: Irssi::channel_find(channel)");
    {
	char *	channel = (char *)SvPV_nolen(ST(0));
	Irssi__Channel	RETVAL;
#line 19 "Channel.xs"
	RETVAL = channel_find(NULL, channel);
#line 47 "Channel.c"
	ST(0) = iobject_bless((SERVER_REC *)RETVAL);

	sv_2mortal(ST(0));
    }
    XSRETURN(1);
}

XS(XS_Irssi__Server_channels); /* prototype to pass -Wmissing-prototypes */
XS(XS_Irssi__Server_channels)
{
    dXSARGS;
    if (items != 1)
	Perl_croak(aTHX_ "Usage: Irssi::Server::channels(server)");
    SP -= items;
    {
	Irssi__Server	server = irssi_ref_object(ST(0));
#line 31 "Channel.xs"
	GSList *tmp;
#line 66 "Channel.c"
#line 33 "Channel.xs"
	for (tmp = server->channels; tmp != NULL; tmp = tmp->next) {
		XPUSHs(sv_2mortal(iobject_bless((CHANNEL_REC *) tmp->data)));
	}
#line 71 "Channel.c"
	PUTBACK;
	return;
    }
}

XS(XS_Irssi__Server_channels_join); /* prototype to pass -Wmissing-prototypes */
XS(XS_Irssi__Server_channels_join)
{
    dXSARGS;
    if (items != 3)
	Perl_croak(aTHX_ "Usage: Irssi::Server::channels_join(server, channels, automatic)");
    {
	Irssi__Server	server = irssi_ref_object(ST(0));
	char *	channels = (char *)SvPV_nolen(ST(1));
	int	automatic = (int)SvIV(ST(2));
#line 43 "Channel.xs"
	server->channels_join(server, channels, automatic);
#line 89 "Channel.c"
    }
    XSRETURN_EMPTY;
}

XS(XS_Irssi__Server_channel_find); /* prototype to pass -Wmissing-prototypes */
XS(XS_Irssi__Server_channel_find)
{
    dXSARGS;
    if (items != 2)
	Perl_croak(aTHX_ "Usage: Irssi::Server::channel_find(server, name)");
    {
	Irssi__Server	server = irssi_ref_object(ST(0));
	char *	name = (char *)SvPV_nolen(ST(1));
	Irssi__Channel	RETVAL;

	RETVAL = channel_find(server, name);
	ST(0) = iobject_bless((SERVER_REC *)RETVAL);

	sv_2mortal(ST(0));
    }
    XSRETURN(1);
}

XS(XS_Irssi__Server_nicks_get_same); /* prototype to pass -Wmissing-prototypes */
XS(XS_Irssi__Server_nicks_get_same)
{
    dXSARGS;
    if (items != 2)
	Perl_croak(aTHX_ "Usage: Irssi::Server::nicks_get_same(server, nick)");
    SP -= items;
    {
	Irssi__Server	server = irssi_ref_object(ST(0));
	char *	nick = (char *)SvPV_nolen(ST(1));
#line 55 "Channel.xs"
	GSList *list, *tmp;
#line 125 "Channel.c"
#line 57 "Channel.xs"
	list = nicklist_get_same(server, nick);

	for (tmp = list; tmp != NULL; tmp = tmp->next->next) {
		XPUSHs(sv_2mortal(iobject_bless((CHANNEL_REC *) tmp->data)));
		XPUSHs(sv_2mortal(iobject_bless((NICK_REC *) tmp->next->data)));
	}
	g_slist_free(list);
#line 134 "Channel.c"
	PUTBACK;
	return;
    }
}

XS(XS_Irssi__Channel_destroy); /* prototype to pass -Wmissing-prototypes */
XS(XS_Irssi__Channel_destroy)
{
    dXSARGS;
    if (items != 1)
	Perl_croak(aTHX_ "Usage: Irssi::Channel::destroy(channel)");
    {
	Irssi__Channel	channel = irssi_ref_object(ST(0));

	channel_destroy(channel);
    }
    XSRETURN_EMPTY;
}

XS(XS_Irssi__Channel_nick_insert); /* prototype to pass -Wmissing-prototypes */
XS(XS_Irssi__Channel_nick_insert)
{
    dXSARGS;
    if (items != 2)
	Perl_croak(aTHX_ "Usage: Irssi::Channel::nick_insert(channel, nick)");
    {
	Irssi__Channel	channel = irssi_ref_object(ST(0));
	Irssi__Nick	nick = irssi_ref_object(ST(1));
#line 78 "Channel.xs"
	nicklist_insert(channel, nick);
#line 165 "Channel.c"
    }
    XSRETURN_EMPTY;
}

XS(XS_Irssi__Channel_nick_remove); /* prototype to pass -Wmissing-prototypes */
XS(XS_Irssi__Channel_nick_remove)
{
    dXSARGS;
    if (items != 2)
	Perl_croak(aTHX_ "Usage: Irssi::Channel::nick_remove(channel, nick)");
    {
	Irssi__Channel	channel = irssi_ref_object(ST(0));
	Irssi__Nick	nick = irssi_ref_object(ST(1));
#line 85 "Channel.xs"
	nicklist_remove(channel, nick);
#line 181 "Channel.c"
    }
    XSRETURN_EMPTY;
}

XS(XS_Irssi__Channel_nick_find); /* prototype to pass -Wmissing-prototypes */
XS(XS_Irssi__Channel_nick_find)
{
    dXSARGS;
    if (items != 2)
	Perl_croak(aTHX_ "Usage: Irssi::Channel::nick_find(channel, nick)");
    {
	Irssi__Channel	channel = irssi_ref_object(ST(0));
	char *	nick = (char *)SvPV_nolen(ST(1));
	Irssi__Nick	RETVAL;
#line 92 "Channel.xs"
	RETVAL = nicklist_find(channel, nick);
#line 198 "Channel.c"
	ST(0) = iobject_bless((SERVER_REC *)RETVAL);

	sv_2mortal(ST(0));
    }
    XSRETURN(1);
}

XS(XS_Irssi__Channel_nick_find_mask); /* prototype to pass -Wmissing-prototypes */
XS(XS_Irssi__Channel_nick_find_mask)
{
    dXSARGS;
    if (items != 2)
	Perl_croak(aTHX_ "Usage: Irssi::Channel::nick_find_mask(channel, mask)");
    {
	Irssi__Channel	channel = irssi_ref_object(ST(0));
	char *	mask = (char *)SvPV_nolen(ST(1));
	Irssi__Nick	RETVAL;
#line 101 "Channel.xs"
	RETVAL = nicklist_find_mask(channel, mask);
#line 218 "Channel.c"
	ST(0) = iobject_bless((SERVER_REC *)RETVAL);

	sv_2mortal(ST(0));
    }
    XSRETURN(1);
}

XS(XS_Irssi__Channel_nicks); /* prototype to pass -Wmissing-prototypes */
XS(XS_Irssi__Channel_nicks)
{
    dXSARGS;
    if (items != 1)
	Perl_croak(aTHX_ "Usage: Irssi::Channel::nicks(channel)");
    SP -= items;
    {
	Irssi__Channel	channel = irssi_ref_object(ST(0));
#line 109 "Channel.xs"
	GSList *list, *tmp;
#line 237 "Channel.c"
#line 111 "Channel.xs"
	list = nicklist_getnicks(channel);

	for (tmp = list; tmp != NULL; tmp = tmp->next) {
		XPUSHs(sv_2mortal(iobject_bless((NICK_REC *) tmp->data)));
	}
	g_slist_free(list);
#line 245 "Channel.c"
	PUTBACK;
	return;
    }
}

#ifdef __cplusplus
extern "C"
#endif
XS(boot_Irssi__Channel); /* prototype to pass -Wmissing-prototypes */
XS(boot_Irssi__Channel)
{
    dXSARGS;
    char* file = __FILE__;

    XS_VERSION_BOOTCHECK ;

        newXSproto("Irssi::channels", XS_Irssi_channels, file, "");
        newXSproto("Irssi::channel_find", XS_Irssi_channel_find, file, "$");
        newXSproto("Irssi::Server::channels", XS_Irssi__Server_channels, file, "$");
        newXSproto("Irssi::Server::channels_join", XS_Irssi__Server_channels_join, file, "$$$");
        newXSproto("Irssi::Server::channel_find", XS_Irssi__Server_channel_find, file, "$$");
        newXSproto("Irssi::Server::nicks_get_same", XS_Irssi__Server_nicks_get_same, file, "$$");
        newXSproto("Irssi::Channel::destroy", XS_Irssi__Channel_destroy, file, "$");
        newXSproto("Irssi::Channel::nick_insert", XS_Irssi__Channel_nick_insert, file, "$$");
        newXSproto("Irssi::Channel::nick_remove", XS_Irssi__Channel_nick_remove, file, "$$");
        newXSproto("Irssi::Channel::nick_find", XS_Irssi__Channel_nick_find, file, "$$");
        newXSproto("Irssi::Channel::nick_find_mask", XS_Irssi__Channel_nick_find_mask, file, "$$");
        newXSproto("Irssi::Channel::nicks", XS_Irssi__Channel_nicks, file, "$");
    XSRETURN_YES;
}

