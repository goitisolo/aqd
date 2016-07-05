# small python script to split a script to multiple xquery files.
# This can help us run individual checks for profiling purposes.
# TODO: Work in progress

import codecs
if __name__ == '__main__':
    f = codecs.open('aqd_check_g-1.0.xquery', encoding='utf-8')
    text = ""
    for line in f:
        text = text + line
    output = """
    {code}
    """
    blocks = [block.strip() for block in text.split("(:") if block.strip()]
    for n, block in enumerate(blocks):
        code = "\n".join(block.splitlines()[1:])
        write = open("split/s" + str(n) + ".xquery", "w")
        write.write(output.format(code=code))
        #print(n)