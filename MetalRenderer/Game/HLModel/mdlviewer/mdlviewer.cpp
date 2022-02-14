/***
*
*    Copyright (c) 1996-2002, Valve LLC. All rights reserved.
*
****/
// updates:
// 1-4-98    fixed initialization

#include <stdio.h>

//#include <windows.h>
//
//#include <gl\gl.h>
//#include <gl\glu.h>
//#include <gl\glut.h>
//
//#include "mathlib.h"
//#include "../../public/steam/steamtypes.h" // defines int32, required by studio.h
//#include "..\..\engine\studio.h"

#include "studio.hpp"
#include "mdlviewer.hpp"

vec3_t        g_vright;        // needs to be set to viewer's right in order for chrome to work


static StudioModel tempmodel;

void mdlviewer_display( )
{
    tempmodel.SetBlending( 0, 0.0 );
    tempmodel.SetBlending( 1, 0.0 );

//    static float prev;
//    float curr = GetTickCount( ) / 1000.0;
//    tempmodel.AdvanceFrame( curr - prev );
//    prev = curr;

    tempmodel.DrawModel( );
}


void mdlviewer_init( char *modelname )
{
    tempmodel.Init( modelname );
    tempmodel.SetSequence( 0 );

    tempmodel.SetController( 0, 0.0 );
    tempmodel.SetController( 1, 0.0 );
    tempmodel.SetController( 2, 0.0 );
    tempmodel.SetController( 3, 0.0 );
    tempmodel.SetMouth( 0 );
}


void mdlviewer_nextsequence( void )
{
    int iSeq = tempmodel.GetSequence( );
    if (iSeq == tempmodel.SetSequence( iSeq + 1 ))
    {
        tempmodel.SetSequence( 0 );
    }
}
