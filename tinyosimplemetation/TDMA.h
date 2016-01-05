/*
-----------------------------------------------------------------------
--                               ITEM                                --
--                Integrated TDMA E-ASAP Module (ITEM)               --
--                                                                   --
--                     Copyright (C) 2008                            --
-- Department of Control Engineering FEE CTU Prague, Czech Republic  --
--                     http://dce.felk.cvut.cz                       --
--                                                                   --
-- Author: 	Pavel Benes	<benesp5@fel.cvut.cz>                --
-- Advisor: 	Jiri Trdlicka	<trdlij1@gmail.com>                  --
--                                                                   --
-- version: 2.0    24.6.2008                                         --
-----------------------------------------------------------------------

This file is part of ITEM project.

    ITEM is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    ITEM is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with Foobar.  If not, see <http://www.gnu.org/licenses/>.
    
*/

/**
 * TDMA Header
 *
 * @author	Pavel Benes <benesp5@fel.cvut.cz>
 * @version 	2.0, Jun 24, 2008
 **/


#ifndef TDMA_H
  #define TDMA_H

  #ifndef TOS_TIME_INCLUDED
    #define TOS_TIME_INCLUDED
    #include "SimpleTime.h"
  #endif //TOS_TIME_INCLUDED

  /*******************/
  /*** Definitions ***/
  /*******************/

  #ifndef TTIME_DEF
    #define TTIME_DEF
    typedef tos_time_t tTime;
  #endif //TTIME_DEF


  #ifndef DEFAULT_INTERVAL
    #define DEFAULT_INTERVAL 1024 //1000ms
  #endif

  #ifndef MIN_FRAME_LENGTH
    #define MIN_FRAME_LENGTH 4
  #endif
  
  #ifndef MAX_FRAME_LENGTH
    #define MAX_FRAME_LENGTH 256
  #endif  

  #ifndef NODE_DEF
    #define NODE_DEF
    typedef uint16_t tID;
    typedef uint16_t tFrame;
    typedef uint16_t tSlot;
  #endif
  
  enum
  {
    //DEFAULT_INTERVAL = 1000,  //1000 ms
    //DEFAULT_FRAME = 4,

    //  MIN_FRAME_LENGTH = 2,
  
    MIN_INTERVAL = 10, //10 ms
    MAX_INTERVAL = 65535, //ca 65 s
   
    MIN_ADJUST = 1, // 1 ms
    MAX_ADJUST = 10, //10 %
  };


  /*** RETURN MESSAGES ***/
  enum
  {
    TDMA_E_ALREADY_RUNNING = 0xBC,
    TDMA_E_INVALID_INTERVAL = 0xBD,
    TDMA_E_INVALID_FRAME_LENGTH = 0xBE,
    TDMA_E_INVALID_ARGUMENT = 0xBF,
  };

#endif //TDMA_H
