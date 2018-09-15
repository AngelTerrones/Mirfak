/*
 * Copyright (C) 2018 Angel Terrones <angelterrones@gmail.com>
 *
 * Permission to use, copy, modify, and/or distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 */

#include <chrono>
#include <atomic>
#include <signal.h>
#include "coretb.h"
#include "defines.h"

static std::atomic_bool quit(false);

// -----------------------------------------------------------------------------
void intHandler(int signo){
        printf("\r[SIGNAL] Quit...\n");
        fflush(stdout);
        quit = true;
        signal(SIGINT, SIG_DFL); // just in case...
}
// -----------------------------------------------------------------------------
CORETB::CORETB() : Testbench(TBFREQ, TBTS), m_exitCode(-1) {
}
// -----------------------------------------------------------------------------
int CORETB::SimulateCore(const std::string &progfile, const unsigned long max_time) {
        bool ok        = false;
        bool notimeout = max_time == 0;
        // Initial values
        m_top->xint_meip_i = 0;
        m_top->xint_mtip_i = 0;
        m_top->xint_msip_i = 0;
        // -------------------------------------------------------------
        LoadMemory(progfile);
        Reset();
        while ((getTime() <= max_time || notimeout) && !Verilated::gotFinish() && !quit) {
                Tick();
                if (CheckTOHOST(ok))
                        break;
                CheckInterrupts();
        }
        // -------------------------------------------------------------
        Tick();
        return PrintExitMessage(ok, max_time);
}
// -----------------------------------------------------------------------------
uint32_t CORETB::PrintExitMessage(const bool ok, const unsigned long max_time) {
        uint32_t exit_code;
        if (ok){
                printf(ANSI_COLOR_GREEN "Simulation done. Time %u\n" ANSI_COLOR_RESET, getTime());
                exit_code = 0;
        } else if (getTime() < max_time || max_time == 0) {
                printf(ANSI_COLOR_RED "Simulation error. Exit code: %08X. Time: %u\n" ANSI_COLOR_RESET, m_exitCode, getTime());
                exit_code = 1;
        } else {
                printf(ANSI_COLOR_MAGENTA "Simulation error. Timeout. Time: %u\n" ANSI_COLOR_RESET, getTime());
                exit_code = 2;
        }
        return exit_code;
}
// -----------------------------------------------------------------------------
bool CORETB::CheckTOHOST(bool &ok) {
        svSetScope(svGetScopeFromName("TOP.top.memory")); // Set the scope before using DPI functions
        uint32_t tohost = ram_v_dpi_read_word(TOHOST);
        if (tohost == 0)
                return false;
        bool isPtr = (tohost - MEMSTART) <= MEMSZ;
        bool _exit = tohost == 1 || not isPtr;
        ok         = tohost == 1;
        m_exitCode = tohost;
        if (not _exit) {
                const uint32_t data0 = tohost;
                const uint32_t data1 = data0 + 8; // 64-bit aligned
                if (ram_v_dpi_read_word(data0) == SYSCALL and ram_v_dpi_read_word(data1) == 1) {
                        SyscallPrint(data0);
                        ram_v_dpi_write_word(FROMHOST, 1); // reset to inital state
                        ram_v_dpi_write_word(TOHOST, 0);   // reset to inital state
                } else {
                        _exit = true;
                }
        }
        return _exit;
}
// -----------------------------------------------------------------------------
void CORETB::CheckInterrupts() {
        svSetScope(svGetScopeFromName("TOP.top.memory")); // Set the scope before using DPI functions
        m_top->xint_meip_i = ram_v_dpi_read_word(XINT_E) != 0;
        m_top->xint_mtip_i = ram_v_dpi_read_word(XINT_T) != 0;
        m_top->xint_msip_i = ram_v_dpi_read_word(XINT_S) != 0;
}
// -----------------------------------------------------------------------------
void CORETB::SyscallPrint(const uint32_t base_addr) const {
        svSetScope(svGetScopeFromName("TOP.top.memory")); // Set the scope before using DPI functions
        const uint64_t data_addr = ram_v_dpi_read_word(base_addr + 16); // dword 2: offset = 16 bytes.
        const uint64_t size      = ram_v_dpi_read_word(base_addr + 24); // dword 3: offset = 24 bytes.
        for (uint32_t ii = 0; ii < size; ii++) {
                printf("%c", ram_v_dpi_read_byte(data_addr + ii));
        }
}
// -----------------------------------------------------------------------------
void CORETB::LoadMemory(const std::string &progfile) {
        svSetScope(svGetScopeFromName("TOP.top.memory"));
        ram_v_dpi_load(progfile.data());
        printf(ANSI_COLOR_YELLOW "Executing file: %s\n" ANSI_COLOR_RESET, progfile.c_str());
}
