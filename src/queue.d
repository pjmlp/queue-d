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
import std.c.stdlib;
import std.c.string;

// Maximum available storage size
const int MAX_STORAGE = 2048;


// Bits to shift around
const int BIT_SHIFT = 12;

// The set of bits that contain the value of the next pointer
const int LOWER_BITS = 0x0FFF;

// storage area
byte data[MAX_STORAGE];

// The queue data type
alias void Q;

/**
* Helper function. Dumps the queue contents in a sequence
* of (value, next) elements.
*
* @param q The queue to dump. Cannot be null.
*/
void dump_queue (Q *q)
{
    assert(q != null);
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
    writef("\n");
}

void main() {
    initialize_storage();
    Q * q0 = create_queue();
    enqueue_byte(q0, 0);
    enqueue_byte(q0, 1);
    Q * q1 = create_queue();
    enqueue_byte(q1, 3);
    enqueue_byte(q0, 2);
    enqueue_byte(q1, 4);
    writef("%d ", dequeue_byte(q0));
    writef("%d\n", dequeue_byte(q0));
    enqueue_byte(q0, 5);
    enqueue_byte(q1, 6);
    writef("%d ", dequeue_byte(q0));
    writef("%d\n", dequeue_byte(q0));
    destroy_queue(q0);
    writef("%d ", dequeue_byte(q1));
    writef("%d ", dequeue_byte(q1));
    writef("%d\n", dequeue_byte(q1));
    destroy_queue(q1);
}

void on_out_of_memory() {
    writef("Not enough memory available. Exiting application\n");
    exit(-1);
}

void on_illegal_operation() {
    writef("An invalid queue operation has been requested. Exiting application\n");
    exit(-2);
}

void initialize_storage() {
    memset(data.ptr, 0, MAX_STORAGE);
    int* free_list = cast(int*)(data);
    *free_list = int.sizeof; // Make the free list point for the first free element
}

void* allocate_storage() {
    int* free_list = cast(int*)(data);
    if (*free_list == 0) {
        on_out_of_memory(); // cannot fullfil request
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

void release_storage(void* mem) {
    int* free_list = cast(int*)(data);
    int* cell = cast(int*)(mem);
    *cell = *free_list;
    *free_list = cast(byte*)(mem) - data.ptr;
}

Q * create_queue() {
    int *queue = cast(int*)(allocate_storage());
    *queue = 0;
    return queue;
}

void destroy_queue(Q * q) {
    assert(q != null);
    int *queue = cast(int*)(q);
    int next = *queue & LOWER_BITS;
    while (next != 0) {
        byte *mem = data.ptr + next;
        next = *(cast(int*)(mem)) & LOWER_BITS;
        release_storage(mem);
    }

    release_storage(q);
}

void enqueue_byte(Q * q, byte b) {
    assert(q != null);
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
        int *cell = cast(int*)(allocate_storage());
        *cell = b << BIT_SHIFT;
        int *last_cell;
        if (previous == 0) {
            last_cell = queue;
        } else {
            last_cell = cast(int*)(data.ptr + previous);
        }
        *last_cell = (*last_cell & 0xF000) | (cast(byte*)(cell) - data.ptr);
    }
}

byte dequeue_byte(Q * q) {
    assert(q != null);
    int *queue = cast(int*)(q);
    if (*queue == 0) {
        on_illegal_operation();
    }
    byte value = cast(byte)(*queue >> BIT_SHIFT);

    int next = *queue & LOWER_BITS;
    if (next != 0 && next != LOWER_BITS) {
        int *cell = cast(int*)(data.ptr + next);
        *queue = *cell;
        release_storage(cell);
    } else {
        *queue = 0;
    }

    return value;
}
