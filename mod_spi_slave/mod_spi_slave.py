
def generate_c_code(icosoc_h, icosoc_c, mod):
    code = """
__attribute__ ((section (".text.sram"))) static inline uint32_t icosoc_@name@_xfer(uint32_t value)  
{
    *(volatile uint32_t*)(0x20000004 + @addr@ * 0x10000) = value;
    return *(volatile uint32_t*)(0x20000008 + @addr@ * 0x10000);
}

__attribute__ ((section (".text.sram"))) static inline uint32_t icosoc_@name@_status()  
{
    return *(volatile uint32_t*)(0x20000000 + @addr@ * 0x10000);
}

"""

    code = code.replace("@name@", mod["name"])
    code = code.replace("@addr@", mod["addr"])
    icosoc_h.append(code)

