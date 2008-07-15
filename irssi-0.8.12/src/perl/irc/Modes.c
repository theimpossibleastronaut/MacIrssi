/*
 * This file was generated automatically by xsubpp version 1.9508 from the
 * contents of Modes.xs. Do not edit this file, edit Modes.xs instead.
 *
 *	ANY CHANGES MADE HERE WILL BE LOST!
 *
 */

#line 1 "Modes.xs"
#include "module.h"

#line 13 "Modes.c"

XS(XS_Irssi__Irc_modes_join); /* prototype to pass -Wmissing-prototypes */
XS(XS_Irssi__Irc_modes_join)
{
    dXSARGS;
    if (items != 4)
	Perl_croak(aTHX_ "Usage: Irssi::Irc::modes_join(server, old, mode, channel)");
    SP -= items;
    {
	Irssi__Irc__Server	server = irssi_ref_object(ST(0));
	char *	old = (char *)SvPV_nolen(ST(1));
	char *	mode = (char *)SvPV_nolen(ST(2));
	int	channel = (int)SvIV(ST(3));
#line 13 "Modes.xs"
	char *ret;
#line 29 "Modes.c"
#line 15 "Modes.xs"
	ret = modes_join(server, old, mode, channel);
	XPUSHs(sv_2mortal(new_pv(ret)));
	g_free(ret);
#line 34 "Modes.c"
	PUTBACK;
	return;
    }
}


XS(XS_Irssi__Irc__Channel_ban_get_mask); /* prototype to pass -Wmissing-prototypes */
XS(XS_Irssi__Irc__Channel_ban_get_mask)
{
    dXSARGS;
    if (items != 3)
	Perl_croak(aTHX_ "Usage: Irssi::Irc::Channel::ban_get_mask(channel, nick, ban_type)");
    SP -= items;
    {
	Irssi__Irc__Channel	channel = irssi_ref_object(ST(0));
	char *	nick = (char *)SvPV_nolen(ST(1));
	int	ban_type = (int)SvIV(ST(2));
#line 29 "Modes.xs"
	char *ret;
#line 54 "Modes.c"
#line 31 "Modes.xs"
	ret = ban_get_mask(channel, nick, ban_type);
	XPUSHs(sv_2mortal(new_pv(ret)));
	g_free(ret);
#line 59 "Modes.c"
	PUTBACK;
	return;
    }
}


XS(XS_Irssi__Irc__Channel_banlist_add); /* prototype to pass -Wmissing-prototypes */
XS(XS_Irssi__Irc__Channel_banlist_add)
{
    dXSARGS;
    if (items != 4)
	Perl_croak(aTHX_ "Usage: Irssi::Irc::Channel::banlist_add(channel, ban, nick, time)");
    {
	Irssi__Irc__Channel	channel = irssi_ref_object(ST(0));
	char *	ban = (char *)SvPV_nolen(ST(1));
	char *	nick = (char *)SvPV_nolen(ST(2));
	time_t	time = (time_t)SvNV(ST(3));
	Irssi__Irc__Ban	RETVAL;

	RETVAL = banlist_add(channel, ban, nick, time);
	ST(0) = plain_bless(RETVAL, "Irssi::Irc::Ban");

	sv_2mortal(ST(0));
    }
    XSRETURN(1);
}


XS(XS_Irssi__Irc__Channel_banlist_remove); /* prototype to pass -Wmissing-prototypes */
XS(XS_Irssi__Irc__Channel_banlist_remove)
{
    dXSARGS;
    if (items != 3)
	Perl_croak(aTHX_ "Usage: Irssi::Irc::Channel::banlist_remove(channel, ban, nick)");
    {
	Irssi__Irc__Channel	channel = irssi_ref_object(ST(0));
	char *	ban = (char *)SvPV_nolen(ST(1));
	char *	nick = (char *)SvPV_nolen(ST(2));

	banlist_remove(channel, ban, nick);
    }
    XSRETURN_EMPTY;
}

#ifdef __cplusplus
extern "C"
#endif
XS(boot_Irssi__Irc__Modes); /* prototype to pass -Wmissing-prototypes */
XS(boot_Irssi__Irc__Modes)
{
    dXSARGS;
    char* file = __FILE__;

    XS_VERSION_BOOTCHECK ;

        newXSproto("Irssi::Irc::modes_join", XS_Irssi__Irc_modes_join, file, "$$$$");
        newXSproto("Irssi::Irc::Channel::ban_get_mask", XS_Irssi__Irc__Channel_ban_get_mask, file, "$$$");
        newXSproto("Irssi::Irc::Channel::banlist_add", XS_Irssi__Irc__Channel_banlist_add, file, "$$$$");
        newXSproto("Irssi::Irc::Channel::banlist_remove", XS_Irssi__Irc__Channel_banlist_remove, file, "$$$");
    XSRETURN_YES;
}

