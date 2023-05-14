#include <sys/mman.h>
#include <stdio.h>
#include <errno.h>

int main() {
        size_t total_leaks = 0;
        for (int shift=12; shift<=16; shift++) {
                size_t size = ((size_t)1)<<shift;
                for (int i=0; i<5000; ++i) {
                        void* m = mmap(NULL, size, PROT_READ | PROT_WRITE,
                                       MAP_PRIVATE | MAP_ANONYMOUS | MAP_32BIT, -1, 0);
                        if (m == MAP_FAILED || m == NULL) {
                                printf(
                                        "Failed. m=%p size=%zd (1<<%d) i=%d "
                                        " errno=%d total_leaks=%zd (%zd MiB)\n",
                                        m, size, shift, i, errno,
                                        total_leaks, total_leaks / 1024 / 1024);
                                return 1;
                        }
                        total_leaks += size;
                }
        }
        printf("Success.\n");
        return 0;
}

