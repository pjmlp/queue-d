/* queue.d - implementation of the game studio challenge
* Copyright (C) 2012  Paulo Pinto
*
* This library is free software; you can redistribute it and/or
* modify it under the terms of the GNU Lesser General Public
* License as published by the Free Software Foundation; either
* version 2 of the License, or (at your option) any later version.
*
* This library is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* Lesser General Public License for more details.
*
* You should have received a copy of the GNU Lesser General Public
* License along with this library; if not, write to the
* Free Software Foundation, Inc., 59 Temple Place - Suite 330,
* Boston, MA 02111-1307, USA.
*/

import std.stdio;
import core.stdc.stdlib;
import core.stdc.string;

/// Maximum available storage size
const int MAX_STORAGE = 2048;


/// Bits to shift around
const int BIT_SHIFT = 12;

/// The set of bits that contain the value of the next pointer
const int LOWER_BITS = 0x0FFF;

/// storage area
byte[MAX_STORAGE] data;

/// The queue data type
alias Q = void;

/**
 * Helper function. Dumps the queue contents in a sequence
 * of (value, next) elements.
 *
 * Params:
 *  q = The queue to dump. Cannot be null.
 */
void dumpQueue (Q *q)
in
{
  assert(q != null);
}
do
{
  writef ("Printing Queue Debugging Info\n");
  int *queue = cast(int*)(q);
  if (*queue == 0) {
    writef ("Empty queue!\n");
  }
  int next = *queue & LOWER_BITS;
  writef ("(%d, %d) ", *queue >> BIT_SHIFT, next);
  while (next != 0 && next != LOWER_BITS) {
    queue = cast(int*)(data.ptr + next);
    next = *queue & LOWER_BITS;
    writef ("(%d, %d) ", *queue >> BIT_SHIFT, next);
    
  }
  writeln;
}

void main() {
  initializeStorage();
  Q * q0 = createQueue();
  enqueueByte(q0, 0);
  enqueueByte(q0, 1);
  Q * q1 = createQueue();
  enqueueByte(q1, 3);
  enqueueByte(q0, 2);
  enqueueByte(q1, 4);
  writef("%d ", dequeueByte(q0));
  writef("%d\n", dequeueByte(q0));
  enqueueByte(q0, 5);
  enqueueByte(q1, 6);
  writef("%d ", dequeueByte(q0));
  writef("%d\n", dequeueByte(q0));
  destroyQueue(q0);
  writef("%d ", dequeueByte(q1));
  writef("%d ", dequeueByte(q1));
  writefln("%d", dequeueByte(q1));
  destroyQueue(q1);
}


/**
 * Called by the queue routines when the storage is
 * exhausted. It exits to the operating system.
 * 
 * On a real system, this would be an callback given into this
 * module.
 */
void onOutOfMemory() {
  writef("Not enough memory available. Exiting application\n");
  exit(-1);
}

/**
 * Called by the queue routines when the an invalid
 * operation is attempted. It exits to the operating system.
 * 
 * On a real system, this would be an callback given into this
 * module.
 */
void onIllegalOperation() {
  writef("An invalid queue operation has been requested. Exiting application\n");
  exit(-2);
}

/**
 * Makes sure all required data structures have
 * a proper value.
 */
void initializeStorage() {

  memset(data.ptr, 0, MAX_STORAGE);
  int* free_list = cast(int*)(data);
  *free_list = int.sizeof; // Make the free list point for the first free element
}

/**
 * Allocates a fixed block of memory for the queue.
 * If no memory is available, the function onOutOfMemory is called().
 *
 * Returns:
 *  A new initialized memory block.
 */
void* allocateStorage()
out(result)
{
	assert(result != null);
}
do
{
  int* free_list = cast(int*)(data);
  if (*free_list == 0) {
    onOutOfMemory(); // cannot fullfil request
  }
  
  int *cell = cast(int*)(data.ptr + *free_list);
  if (*cell == 0) {
    *free_list += int.sizeof;
  } else {
    *free_list = *cell;
    *cell = 0;
  }
  
  return cell;
}

/**
 * Returns the memory block back to the free list.
 *
 * Params:
 *  mem = Memory block to return. Cannot be null.
 */
void releaseStorage(void* mem)
in
{
  assert (mem != null);
}
do
{
  int* free_list = cast(int*)(data);
  int* cell = cast(int*)(mem);
  *cell = *free_list;
  *free_list = cast(int)(cast(byte*)(mem) - data.ptr);
}

/**
 * Initializes a new queue
 *
 * Return:
 *  A new object representing a queue.
 */
Q* createQueue()
out(result)
{
  assert (result != null);
}
do
{
  int *queue = cast(int*)(allocateStorage());
  *queue = 0;
  return queue;
}

/**
 * Destroys the queue by making its space available
 * for further operations.
 *
 * Params:
 *  q = The queue to dump. Cannot be null.
 */
void destroyQueue(Q * q)
in
{
  assert(q != null);
}
do
{
  int *queue = cast(int*)(q);
  int next = *queue & LOWER_BITS;
  while (next != 0) {
    byte *mem = data.ptr + next;
    next = *(cast(int*)(mem)) & LOWER_BITS;
    releaseStorage(mem);
  }
  
  releaseStorage(q);
}

/**
 * Places a byte into the queue.
 * If the storage is exhausted the function
 * onOutOfMemory() will be called.
 *
 * Params:
 *  q = The queue to dump. Cannot be null.
 *  b = byte to enqueue.
 */
void enqueueByte(Q * q, byte b)
in
{
  assert(q != null);
}
do
{
  int *queue = cast(int*)(q);
  if (*queue == 0) {
    *queue = b << BIT_SHIFT | LOWER_BITS;
  } else {
    int next = *queue & LOWER_BITS;
    int previous = 0;
    if (next == LOWER_BITS) {
      previous = 0;
    } else {
      while (next != 0) {
        byte *mem = data.ptr + next;
        previous = next;
        next = *(cast(int*)(mem)) & LOWER_BITS;
      }
    }
    int *cell = cast(int*)(allocateStorage());
    *cell = b << BIT_SHIFT;
    int *last_cell;
    if (previous == 0) {
      last_cell = queue;
    } else {
      last_cell = cast(int*)(data.ptr + previous);
    }
    *last_cell = cast(int)((*last_cell & 0xF000) | (cast(byte*)(cell) - data.ptr));
  }
}

/**
 * Removes a byte from the queue.
 * If the queue is empty the function
 * onIllegalOperation() will be called.
 *
 * Params:
 *  q = The queue to dump. Cannot be null.
 *
 * Return:
 *  The byte at the top of the queue.
 */
byte dequeueByte(Q * q)
in
{
  assert(q != null);
}
do
{
  int *queue = cast(int*)(q);
  if (*queue == 0) {
    onIllegalOperation();
  }
  byte value = cast(byte)(*queue >> BIT_SHIFT);
  
  const next = *queue & LOWER_BITS;
  if (next != 0 && next != LOWER_BITS) {
    int *cell = cast(int*)(data.ptr + next);
    *queue = *cell;
    releaseStorage(cell);
  } else {
    *queue = 0;
  }
  
  return value;
}
