NRF_POWER->DCDCEN = 0;
// NRF_POWER->DCDCEN = 1;

while (true)
{
    /* Wait with TX OFF. */
    repeat_tx_off();
    // Turn GPIO ON for triggering.
    // NRF_P0->OUTSET = (1ul << 11);
    /* Wait with TX ON but not AES. */
    repeat_tx_carrier();
    // repeat_tx_mod()
    /* Start repeated AES. */
    repeat_aes_soft_ecb();
    /* Start repeated hardware AES using ECB. */
    repeat_aes_hard_ecb_simple_loop_without_counter();
    // repeat_aes_hard_ecb_simple_loop_with_counter();
    repeat_aes_hard_ecb_simple_loop_with_int_sleep();
    /* Start repeated hardware AES using CCM. */
    repeat_aes_hard_ccm();
    // Turn GPIO OFF after triggering.
    // NRF_P0->OUTCLR = (1ul << 11);
}

