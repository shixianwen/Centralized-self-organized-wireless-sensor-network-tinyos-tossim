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
 * EASAPImp interface for internal implementation. Not accessiable from the outside.
 *
 * @author	Pavel Benes <benesp5@fel.cvut.cz>
 * @version 	2.0, Jun 24, 2008
 **/


//includes EASAP;
#include "EASAP.h"

interface EASAPImp
{

  /**
   * Initializes the settings for an individual node.
   *
   * @param pNode Node to initialize. Discarded if <code>NULL</code>.
   **/
  command void initNode(struct Node *pNode);

  /** 
   * Adds a slot to the given node. Discarded if  no memory is available for it.
   *
   * @param slot Slots to be added.
   *
   * @param pNode Reference to node.
   *
   * @return <code>EASAP_SLOT_ADDED</code> if added. 
   *         <code>EASAP_SLOT_EXISTS</code> if it already exists.
   *         <code>EASAP_SLOT_DISCARDED</code> if NOT added due to memory limitations.
   *         <code>EASAP_SLOT_RESERVED</code> if slot is reserved.      
   **/
  command bool addSlot(tSlot slot, struct Node* pNode);

  /** 
   * Adds the given slots to the Slot list.
   *
   * @param slots Slots to be added. First value in the stream determines how many slots there are in the stream.
   * @param pNode
   *    
   * @return <code>TRUE</code> if all slots where added.
   *         <code>FALSE</code> if at least one was not added due to memory limitations.
   **/
  command bool addSlots(tSlot* slots, struct Node* pNode);

  /** 
   * Removes the slot from the node
   *
   * @param slot Slot number to remove.
   *
   * @param pNode reference to remove the slot from.
   *
   * @return <code>TRUE</code> if removed.
   *         <code>FALSE</code> otherwise.
   **/
  command bool removeSlot(tSlot slot, struct Node* pNode);

  /**
   * Clears all the slots from the given node.
   *
   * @param pNode Node to clear the slots from. Discarded if <code>NULL</code>.
   **/
  command void clearSlots(struct Node* pNode);

  /** 
   * Searches the node for the given slot.
   *
   * @param slot Slot to find.
   *
   * @param pNode reference to find the slot in.
   *
   * @return Reference to the found slot, <code>NULL</code> if not found.
   **/
  command struct Slot* findSlot(tSlot slot, struct Node* pNode);

  /** 
   * Appends the given node to the INF list.
   *
   * @param pNode Node to be added to the inf list.
   *
   * @return <code>TRUE</code> if added.
   *         <code>FALSE</code> otherwise.
   **/
  command bool appendNode(struct Node* pNode);

  /** 
   * Compares and updates the node's information in the INF. Discarded if the node doesn't exist.
   *
   * @param id ID of the node.
   *
   * @param slots Slots that it should have. First byte MUST contains the nr of slots there are in the stream.
   *
   * @param frame Frame length it should have.
   *
   * @param cLocalTime Current Local Time.
   * 
   * @param isNeighbour
   **/
  command void updateNodeInfo(tID id, tSlot* slots, tFrame frame, 
					tTime* cLocalTime, nx_uint8_t isNeighbour);  
  command void updateMyNodeInfo(tID id, tSlot* slots, tFrame frame, 
							 tTime* cLocalTime, nx_uint8_t isNeighbour);
  /**
   * Increases the frame length.
   **/
 // command void increaseFrame();


  /**
   * Decreases the frame length.
   **/
 // command void decreaseFrame();

  //将frame设置到指定的长度
 // command void setFrame(uint8_t frame);
}

