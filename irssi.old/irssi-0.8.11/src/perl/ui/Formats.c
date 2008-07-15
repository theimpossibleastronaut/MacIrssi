/*
 * This file was generated automatically by xsubpp version 1.9508 from the
 * contents of Formats.xs. Do not edit this file, edit Formats.xs instead.
 *
 *	ANY CHANGES MADE HERE WILL BE LOST!
 *
 */

#line 1 "Formats.xs"
#include "module.h"

static int magic_free_text_dest(pTHX_ SV *sv, MAGIC *mg)
{
	TEXT_DEST_REC *dest = (TEXT_DEST_REC *) mg->mg_ptr;
	char *target = (char *) dest->target;
	g_free(target);
	g_free(dest);
	mg->mg_ptr = NULL;
	sv_setiv(sv, 0);
	return 0;
}

static MGVTBL vtbl_free_text_dest =
{
    NULL, NULL, NULL, NULL, magic_free_text_dest
};

static SV *perl_format_create_dest(SERVER_REC *server, char *target,
				   int level, WINDOW_REC *window)
{
	TEXT_DEST_REC *dest;
	SV *sv, *ret_sv;

	dest = g_new0(TEXT_DEST_REC, 1);
	format_create_dest(dest, server, g_strdup(target), level, window);

	ret_sv = plain_bless(dest, "Irssi::UI::TextDest");

	sv = *hv_fetch(hvref(ret_sv), "_irssi", 6, 0);
	sv_magic(sv, NULL, '~', NULL, 0);

	SvMAGIC(sv)->mg_private = 0x1551; /* HF */
	SvMAGIC(sv)->mg_virtual = &vtbl_free_text_dest;
	SvMAGIC(sv)->mg_ptr = (char *) dest;

	return ret_sv;
}

#line 50 "Formats.c"
XS(XS_Irssi_format_get_length); /* prototype to pass -Wmissing-prototypes */
XS(XS_Irssi_format_get_length)
{
    dXSARGS;
    if (items != 1)
	Perl_croak(aTHX_ "Usage: Irssi::format_get_length(str)");
    {
	char *	str = (char *)SvPV_nolen(ST(0));
	int	RETVAL;
	dXSTARG;

	RETVAL = format_get_length(str);
	XSprePUSH; PUSHi((IV)RETVAL);
    }
    XSRETURN(1);
}

XS(XS_Irssi_format_real_length); /* prototype to pass -Wmissing-prototypes */
XS(XS_Irssi_format_real_length)
{
    dXSARGS;
    if (items != 2)
	Perl_croak(aTHX_ "Usage: Irssi::format_real_length(str, len)");
    {
	char *	str = (char *)SvPV_nolen(ST(0));
	int	len = (int)SvIV(ST(1));
	int	RETVAL;
	dXSTARG;

	RETVAL = format_real_length(str, len);
	XSprePUSH; PUSHi((IV)RETVAL);
    }
    XSRETURN(1);
}

XS(XS_Irssi_strip_codes); /* prototype to pass -Wmissing-prototypes */
XS(XS_Irssi_strip_codes)
{
    dXSARGS;
    if (items != 1)
	Perl_croak(aTHX_ "Usage: Irssi::strip_codes(input)");
    SP -= items;
    {
	char *	input = (char *)SvPV_nolen(ST(0));
#line 56 "Formats.xs"
	char *ret;
#line 97 "Formats.c"
#line 58 "Formats.xs"
	ret = strip_codes(input);
	XPUSHs(sv_2mortal(new_pv(ret)));
	g_free(ret);
#line 102 "Formats.c"
	PUTBACK;
	return;
    }
}

XS(XS_Irssi_format_create_dest); /* prototype to pass -Wmissing-prototypes */
XS(XS_Irssi_format_create_dest)
{
    dXSARGS;
    if (items < 1 || items > 3)
	Perl_croak(aTHX_ "Usage: Irssi::format_create_dest(target, level=MSGLEVEL_CLIENTNOTICE, window=NULL)");
    SP -= items;
    {
	char *	target = (char *)SvPV_nolen(ST(0));
	int	level;
	Irssi__UI__Window	window;

	if (items < 2)
	    level = MSGLEVEL_CLIENTNOTICE;
	else {
	    level = (int)SvIV(ST(1));
	}

	if (items < 3)
	    window = NULL;
	else {
	    window = irssi_ref_object(ST(2));
	}
#line 69 "Formats.xs"
	XPUSHs(sv_2mortal(perl_format_create_dest(NULL, target, level, window)));
#line 133 "Formats.c"
	PUTBACK;
	return;
    }
}

XS(XS_Irssi__UI__Window_format_get_text); /* prototype to pass -Wmissing-prototypes */
XS(XS_Irssi__UI__Window_format_get_text)
{
    dXSARGS;
    if (items < 5)
	Perl_croak(aTHX_ "Usage: Irssi::UI::Window::format_get_text(window, module, server, target, formatnum, ...)");
    SP -= items;
    {
	Irssi__UI__Window	window = irssi_ref_object(ST(0));
	char *	module = (char *)SvPV_nolen(ST(1));
	Irssi__Server	server = irssi_ref_object(ST(2));
	char *	target = (char *)SvPV_nolen(ST(3));
	int	formatnum = (int)SvIV(ST(4));
#line 83 "Formats.xs"
	TEXT_DEST_REC dest;
	THEME_REC *theme;
	char **charargs;
	char *ret;
	int n;
#line 158 "Formats.c"
#line 89 "Formats.xs"
	charargs = g_new0(char *, items-5+1);
        for (n = 5; n < items; n++) {
		charargs[n-5] = (char *)SvPV(ST(n), PL_na);
	}

	format_create_dest(&dest, server, target, 0, window);
	theme = window_get_theme(dest.window);

	ret = format_get_text_theme_charargs(theme, module, &dest, formatnum, charargs);
	g_free(charargs);

	XPUSHs(sv_2mortal(new_pv(ret)));
	g_free_not_null(ret);
#line 173 "Formats.c"
	PUTBACK;
	return;
    }
}

XS(XS_Irssi__Window_format_create_dest); /* prototype to pass -Wmissing-prototypes */
XS(XS_Irssi__Window_format_create_dest)
{
    dXSARGS;
    if (items < 0 || items > 2)
	Perl_croak(aTHX_ "Usage: Irssi::Window::format_create_dest(window=NULL, level=MSGLEVEL_CLIENTNOTICE)");
    SP -= items;
    {
	Irssi__UI__Window	window;
	int	level;

	if (items < 1)
	    window = NULL;
	else {
	    window = irssi_ref_object(ST(0));
	}

	if (items < 2)
	    level = MSGLEVEL_CLIENTNOTICE;
	else {
	    level = (int)SvIV(ST(1));
	}
#line 112 "Formats.xs"
	XPUSHs(sv_2mortal(perl_format_create_dest(NULL, NULL, level, window)));
#line 203 "Formats.c"
	PUTBACK;
	return;
    }
}

XS(XS_Irssi__Server_format_create_dest); /* prototype to pass -Wmissing-prototypes */
XS(XS_Irssi__Server_format_create_dest)
{
    dXSARGS;
    if (items < 1 || items > 4)
	Perl_croak(aTHX_ "Usage: Irssi::Server::format_create_dest(server, target=NULL, level=MSGLEVEL_CLIENTNOTICE, window=NULL)");
    SP -= items;
    {
	Irssi__Server	server = irssi_ref_object(ST(0));
	char *	target;
	int	level;
	Irssi__UI__Window	window;

	if (items < 2)
	    target = NULL;
	else {
	    target = (char *)SvPV_nolen(ST(1));
	}

	if (items < 3)
	    level = MSGLEVEL_CLIENTNOTICE;
	else {
	    level = (int)SvIV(ST(2));
	}

	if (items < 4)
	    window = NULL;
	else {
	    window = irssi_ref_object(ST(3));
	}
#line 125 "Formats.xs"
	XPUSHs(sv_2mortal(perl_format_create_dest(server, target, level, window)));
#line 241 "Formats.c"
	PUTBACK;
	return;
    }
}

XS(XS_Irssi__UI__TextDest_print); /* prototype to pass -Wmissing-prototypes */
XS(XS_Irssi__UI__TextDest_print)
{
    dXSARGS;
    if (items != 2)
	Perl_croak(aTHX_ "Usage: Irssi::UI::TextDest::print(dest, str)");
    {
	Irssi__UI__TextDest	dest = irssi_ref_object(ST(0));
	char *	str = (char *)SvPV_nolen(ST(1));
#line 136 "Formats.xs"
	printtext_dest(dest, "%s", str);
#line 258 "Formats.c"
    }
    XSRETURN_EMPTY;
}

#ifdef __cplusplus
extern "C"
#endif
XS(boot_Irssi__UI__Formats); /* prototype to pass -Wmissing-prototypes */
XS(boot_Irssi__UI__Formats)
{
    dXSARGS;
    char* file = __FILE__;

    XS_VERSION_BOOTCHECK ;

        newXSproto("Irssi::format_get_length", XS_Irssi_format_get_length, file, "$");
        newXSproto("Irssi::format_real_length", XS_Irssi_format_real_length, file, "$$");
        newXSproto("Irssi::strip_codes", XS_Irssi_strip_codes, file, "$");
        newXSproto("Irssi::format_create_dest", XS_Irssi_format_create_dest, file, "$;$$");
        newXSproto("Irssi::UI::Window::format_get_text", XS_Irssi__UI__Window_format_get_text, file, "$$$$$;@");
        newXSproto("Irssi::Window::format_create_dest", XS_Irssi__Window_format_create_dest, file, ";$$");
        newXSproto("Irssi::Server::format_create_dest", XS_Irssi__Server_format_create_dest, file, "$;$$$");
        newXSproto("Irssi::UI::TextDest::print", XS_Irssi__UI__TextDest_print, file, "$$");
    XSRETURN_YES;
}

