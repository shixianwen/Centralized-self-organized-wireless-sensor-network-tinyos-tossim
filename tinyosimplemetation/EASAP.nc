/*
-----------------------------------------------------------------------
--                               ITEM                                --
--                Integrated TDMA E-ASAP Module (ITEM)               --
--                                                                   --
--                     Copyright (C) 2007                            --
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
 * EASAP Interface
 *
 * For manipulating the INF content.
 *
 * @author	Pavel Benes <benesp5@fel.cvut.cz>
 * @version 	2.0, Jun 24, 2008
 **/


//includes EASAP;
#include "EASAP.h"

interface EASAP
{
  /** 
   * Increases the frame length.
   **/
  //command void sigSlotZero();

  /**
   * Gives the reference to the INF list.
   *
   * @return Reference to the list. NULL if empty 
   **/
  command struct Node* getINF();

  /**
   * Gives the DAT info EXCEPT the currentSlot.
   *
   * @return DAT structure as defined in <code>EASAP.h</code> 
   **/
  //command struct DAT* getDAT();

  /** Gets a slot and assigns it to itself, if possible.
   *
   * @param slotNr slot number if successfull. 0 if not found.
   *
   * @return <code>TRUE</code> if found. <code>FALSE</code> if not (Max frame length has been reached).
   **/
 // command bool getSlot(tSlot* slotNr);

  /** Gets a slot with random time delay and assigns it to itself, if possible.
   *
   **/
 // command void getNewSlotRandTime();

  /** Release all owned slots
   *
   **/
  command void releaseOwnedSlots();
      
  /** Release slots from upper half of frame
   *
   **/
  //command void releaseUpperSlots();


  /* Determines if the given slot is owned by the node.
   *
   * @return <code>TRUE</code> if it is. Else <code>FALSE</code>.
   **/
  command bool isOwnSlot(tSlot slot);

  /** Removes own slot from the list, if it exists
   *
   * @param slot Slot to be removed.
   *
   * @return TRUE if removed. FALSE if not found.
   **/
  command bool removeSlot(tSlot slot);

  /**
   * Return the current set maximum frame length.
   **/
  command tFrame getMaxFrameLength();

  /** 
   * Updates the given node's information to the INF list appropriately as defined in E-ASAP protocol. If the node doesn't exist in the list, it is added as new.
   *
   * @param id ID of the node.
   *
   * @param pSlots Slots assigned to the node. Initial paramater must contain the number of slots that are in the  stream
   *
   * @param frameLength Frame assigned to the node.
   *
   * @param cLocalTime Current local Time.
   *
   * @param isNeighbour Is it a neighbor to the current node (Broadcasting node)
   *
   * @return
   *   <MENU>
   *   <LI><code>TRUE</code> if added. 
   *   <LI><code>FALSE</code> if:<MENU>
   *                             <LI>It already exists
   *                             <LI>No memory available
   *                             <LI>Any of id/slot/frame is invalid.
   *                             </MENU>
   *   </MENU>
   **/
  command bool updateNode(tID id, tSlot* pSlots, tFrame frameLength, 
							  tTime* cLocalTime, uint8_t isNeighbour);							  

  /**
   * Removes the node from the INF list.
   *
   * @param id Node to be removed. Discarded if it doesn't exist
   *
   **/
  command void removeNode(tID id);

  /**
   * Removes all inactive nodes from the INF list. Inactive node is given by all nodes that have older time mark than the given argument.
   *
   * @param timeStampMark Time mark. Oldest allowed time mark for all nodes.
   *
   **/
 // command void removeInactiveNodes(tTime* timeStampMark);
  
  /**
   * Searches for a node by its given id.
   *
   * @param id ID of the node.
   *
   * @return Reference to the found node. <code>NULL</code> if not found.
   **/
  command struct Node* findNode(tID id);
  
  /**
   * Signals when frame length has been changed.
   *
   * @param newframe Frame length of the new frame.
   **/
  event void frameChanged(tFrame newframe);
  event void frameseted(tFrame newframe);

  /**
   * Get slots occupied by the node and its neighbours
   *
   * @return Count of occupied slots.
   **/
  command uint16_t getOccupiedSlots();

  /** Reserve slot
   *
   * @param slot Slot to be reserved.
   *
   * @return TRUE if reserved. FALSE if not.
   **/
  command bool reserveSlot(tSlot slot);
  
  /** Get reserved slots
   *
   * @return pointer to reserved slots array
   **/
  command bool* getReservedSlots();
  
  /** Get nr of reserved slots
   *
   * @return nr of reserved slots
   **/
  command uint16_t nrOfReservedSlots();

  /** Get nr of reserved slots in frame
   *
   * @return nr of reserved slots
   **/
 // command uint8_t nrOfReservedSlotsInHalfFrame();
  command void setFrame(uint16_t frame);
                  
}
