
def generate_c_code(icosoc_h, icosoc_c, mod):
    code = """
static inline void icosoc_@name@_set_status(uint32_t bitmask) {
    *(volatile uint32_t*)(0x20000004 + @addr@ * 0x10000) = bitmask;
}

static inline uint32_t icosoc_@name@_get_status() {
    return *(volatile uint32_t*)(0x20000004 + @addr@ * 0x10000);
}

static inline uint32_t icosoc_@name@_get_io() {
    return *(volatile uint32_t*)(0x20000000 + @addr@ * 0x10000);
}

static inline void icosoc_@name@_set_counter(uint64_t cnt) {
    *(volatile uint32_t*)(0x20000008 + @addr@ * 0x10000) = (cnt >> 32);
    *(volatile uint32_t*)(0x20000008 + @addr@ * 0x10000) = cnt;
}

static inline uint64_t icosoc_@name@_get_counter() {
    uint64_t ret = *(volatile uint32_t*)(0x20000008 + @addr@ * 0x10000);
    ret = (ret << 32) | *(volatile uint32_t*)(0x20000008 + @addr@ * 0x10000);
    return ret;

}

static inline void icosoc_@name@_set_trigger(uint8_t id, uint64_t cnt) {
    *(volatile uint32_t*)(0x20000100 + (id << 2) + @addr@ * 0x10000) = (cnt >> 32);
    *(volatile uint32_t*)(0x20000100 + (id << 2) + @addr@ * 0x10000) = cnt;
}

static inline uint64_t icosoc_@name@_get_trigger(uint8_t id) {
    uint64_t ret = *(volatile uint32_t*)(0x20000100 + (id << 2) + @addr@ * 0x10000);
    ret = (ret << 32) | *(volatile uint32_t*)(0x20000100 + (id << 2) + @addr@ * 0x10000);
    return ret;

}

static inline void icosoc_@name@_set_fifo(uint64_t fifo_in) {
    *(volatile uint32_t*)(0x2000000c + @addr@ * 0x10000) = (fifo_in >> 32);
    *(volatile uint32_t*)(0x2000000c + @addr@ * 0x10000) = fifo_in;
}

static inline uint64_t icosoc_@name@_get_fifo() {
    uint64_t ret = *(volatile uint32_t*)(0x2000000c + @addr@ * 0x10000);
    ret = (ret << 32) | *(volatile uint32_t*)(0x2000000c + @addr@ * 0x10000);
    return ret;

}
"""

    code = code.replace("@name@", mod["name"])
    code = code.replace("@addr@", mod["addr"])
    icosoc_h.append(code)

