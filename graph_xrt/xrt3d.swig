%module XrtGraph

%{
#include "xrt3d.h"
%}

%inline %{
struct xrt3d_info * new_config() {
    struct xrt3d_info * ret_val = (struct xrt3d_info *)malloc(sizeof(struct xrt3d_info));
    ret_val->filename = NULL;
    ret_val->argv = NULL;
    ret_val->x_title = NULL;
    ret_val->y_title = NULL;
    ret_val->z_title = NULL;
    ret_val->data = NULL;
    ret_val->header = NULL;
    ret_val->footer = NULL;
    ret_val->x_labels = NULL;
    ret_val->y_labels = NULL;
    return ret_val;
}

void delete_config(struct xrt3d_info * dead_ptr) {
    free(dead_ptr);
}
%}

%typemap(perl5,in) char ** {
    AV *tempav;
    I32 len;
    int i;
    SV **tv;
    if (!SvROK($source))
        croak("$source is not a reference.");
    if (SvTYPE(SvRV($source)) != SVt_PVAV)
        croak("$source is not an array.");
    tempav = (AV*)SvRV($source);
    len = av_len(tempav);
    $target = (char **) malloc((len+2)*sizeof(char *));
    for (i = 0; i <= len; i++) {
        tv = av_fetch(tempav, i, 0);
        $target[i] = strdup((char *) SvPV(*tv,na));
    }
    $target[i] = 0;
};

// Creates a new Perl array and places a char ** into it
%typemap(perl5,out) char ** {
    AV *myav;
    SV **svs;
    int i = 0,len = 0;
    /* Figure out how many elements we have */
    while ($source[len])
        len++;
    svs = (SV **) malloc(len*sizeof(SV *));
    for (i = 0; i < len ; i++) {
        if($source[i][0] == '\0')
	    svs[i] = &sv_undef; // Empty string -> undef
	else {
            svs[i] = sv_newmortal();
            sv_setpv((SV*)svs[i],$source[i]);
	}
    };
    myav = av_make(len,svs);
    free(svs);
    $target = newRV_noinc((SV*)myav);
    sv_2mortal($target);
    argvi++;
}

%typemap(perl5,in) double ** {
    AV *tempav;
    AV *tempav2;
    I32 len;
    I32 len2;
    int i,j;
    SV **tv;
    SV **tv2;
    if (!SvROK($source))
        croak("$source is not a reference.");
    if (SvTYPE(SvRV($source)) != SVt_PVAV)
        croak("$source is not an array.");
    tempav = (AV*)SvRV($source);
    len = av_len(tempav);
    $target = (double **) malloc((len+1)*sizeof(double *));
    for (i = 0; i <= len; i++) {
        tv = av_fetch(tempav, i, 0);
        if (!SvROK(*tv))
            croak("tv is not a reference.");
        if (SvTYPE(SvRV(*tv)) != SVt_PVAV)
            croak("tv is not an array.");
        tempav2 = (AV*)SvRV(*tv);
        len2 = av_len(tempav2);
        $target[i] = (double *) malloc((len2+1)*sizeof(double));
        for (j = 0; j <= len2; j++) {
            tv2 = av_fetch(tempav2, j, 0);
            $target[i][j] = (double) SvNV(*tv2);
        }
    }
};

%include "xrt3d.h"
