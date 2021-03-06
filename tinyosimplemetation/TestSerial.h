
#ifndef TEST_SERIAL_H
#define TEST_SERIAL_H

typedef struct test_serial_msg {
  uint16_t myaddress;
  uint16_t motheraddress;
  uint32_t tdma_start_time;
  uint16_t framelenghth;
  uint8_t length;
  uint16_t a[8];
} test_serial_msg_t;

enum {
  AM_TEST_SERIAL_MSG = 0x89,
};

#endif
