
// Support for unaligned data access
static inline void write_word(unsigned int val, unsigned short* buf, int offset)
{
    buf[offset + 0] = val & 0xff;
    buf[offset + 1] = (val >> 8) & 0xff;
    buf[offset + 2] = (val >> 16) & 0xff;
    buf[offset + 3] = (val >> 24) & 0xff;
}

static inline unsigned int read_word(unsigned short* buf, int offset)
{
	unsigned int b0 = buf[offset + 0] & 0xff;
	unsigned int b1 = buf[offset + 1] & 0xff;
	unsigned int b2 = buf[offset + 2] & 0xff;
	unsigned int b3 = buf[offset + 3] & 0xff;

	return b0 | (b1 << 8) | (b2 << 16) | (b3 << 24);
}

static inline unsigned int byte_swap(unsigned int in)
{
	unsigned int b0 = in & 0xff;
    unsigned int b1 = (in >> 8) & 0xff;
    unsigned int b2 = (in >> 16) & 0xff;
    unsigned int b3 = (in >> 24) & 0xff;
    unsigned int ret = (b0 << 24) | (b1 << 16) | (b2 << 8) | b3;
    return ret;
}