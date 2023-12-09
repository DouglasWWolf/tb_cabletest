#==============================================================================
#  Date      Vers  Who  Description
# -----------------------------------------------------------------------------
# 06-Dec-23  1.00  DWW  Initial Creation
#==============================================================================
CABLETEST_API_VERSION=1.00

#==============================================================================
# AXI register definitions
#==============================================================================
CABLETEST_BASE=0x1000

       REG_MODULE_REV=$((CABLETEST_BASE +  0*4))
           REG_STATUS=$((CABLETEST_BASE +  1*4))
REG_CYCLES_PER_PACKET=$((CABLETEST_BASE +  2*4))
    REG_PACKET_COUNTH=$((CABLETEST_BASE +  3*4))
    REG_PACKET_COUNTL=$((CABLETEST_BASE +  4*4))
   REG_PACKETS_SENT1H=$((CABLETEST_BASE +  5*4))
   REG_PACKETS_SENT1L=$((CABLETEST_BASE +  6*4))
   REG_PACKETS_SENT2H=$((CABLETEST_BASE +  7*4))
   REG_PACKETS_SENT2L=$((CABLETEST_BASE +  8*4))
   REG_PACKETS_RCVD1H=$((CABLETEST_BASE +  9*4))
   REG_PACKETS_RCVD1L=$((CABLETEST_BASE + 10*4))
   REG_PACKETS_RCVD2H=$((CABLETEST_BASE + 11*4))
   REG_PACKETS_RCVD2L=$((CABLETEST_BASE + 12*4))
          REG_ERRORS1=$((CABLETEST_BASE + 13*4))
          REG_ERRORS2=$((CABLETEST_BASE + 14*4))
         REG_SIMERROR=$((CABLETEST_BASE + 15*4))


#==============================================================================
# This strips underscores from a string and converts it to decimal
#==============================================================================
strip_underscores()
{
    local stripped=$(echo $1 | sed 's/_//g')
    echo $((stripped))
}
#==============================================================================


#==============================================================================
# This displays the upper 32 bits of an integer
#==============================================================================
upper32()
{
    local value=$(strip_underscores $1)
    echo $(((value >> 32) & 0xFFFFFFFF))
}
#==============================================================================



#==============================================================================
# This displays the lower 32 bits of an integer
#==============================================================================
lower32()
{
    local value=$(strip_underscores $1)
    echo $((value & 0xFFFFFFFF))
}
#==============================================================================


#==============================================================================
# This calls the local copy of pcireg
#==============================================================================
pcireg()
{
    axireg $1 $2 $3 $4 $5 $6
}
#==============================================================================


#==============================================================================
# This reads a PCI register and displays its value in decimal
#==============================================================================
read_reg()
{
    # Capture the value of the AXI register
    text=$(pcireg $1)

    # Extract just the first word of that text
    text=($text)

    # Convert the text into a number
    value=$((text))

    # Hand the value to the caller
    echo $value
}
#==============================================================================


#==============================================================================
# reads a 64-bit register
#==============================================================================
read_reg64()
{
    local hi_reg=$1
    local lo_reg=$((hi_reg + 4))

    local msw=$(read_reg $hi_reg)
    local lsw=$(read_reg $lo_reg)

    if [ $(read_reg $hi_reg) -ne $msw ]; then
        msw=$(read_reg $hi_reg)
        lsw=$(read_reg $lo_reg)
    fi

    echo $(((msw << 32) | lsw))
}
#==============================================================================



#==============================================================================
# Displays the "busy" status.  Non-zero = Busy generating packets
#==============================================================================
is_busy()
{
    read_reg $REG_STATUS
}
#==============================================================================


#==============================================================================
# Starts generating the specified number of packets
#
# Returns: 0 on success, 1 on failure
#==============================================================================
start()
{
    local packet_count=$1

    if [ $(is_busy) -ne -0 ]; then
        echo "Generator is busy." 1>&2
        return 1
    elif [ -z $packet_count ]; then
        echo "Missing parameter on start()" 1>&2
        return 1
    else
        pcireg $REG_PACKET_COUNTH $(upper32 $packet_count)
        pcireg $REG_PACKET_COUNTL $(lower32 $packet_count)        
    fi

    return 0
}
#==============================================================================


#==============================================================================
# Displays the number of packets transmitted so far
#==============================================================================
get_packets_sent()
{
   
    if [ "$1" == "1" ]; then
        read_reg64 $REG_PACKETS_SENT1H
    elif [ "$1" == "2" ]; then
        read_reg64 $REG_PACKETS_SENT2H
    else
        echo "Bad parameter [$1] on get_packet_sent()" 1>&2
        echo "0"
        return
    fi
}
#==============================================================================


#==============================================================================
# Displays the total number of packets that will be sent
#==============================================================================
get_packet_count()
{
    read_reg64 $REG_PACKET_COUNTH 
}
#==============================================================================


#==============================================================================
# Displays the number of packets received
#==============================================================================
get_packets_rcvd()
{
    if [ "$1" == "1" ]; then
        read_reg64 $REG_PACKETS_RCVD1H 
    elif [ "$1" == "2" ]; then
        read_reg64 $REG_PACKETS_RCVD2H
    else
        echo "Bad parameter [$1] on get_packet_rcvd()" 1>&2
        echo "0"
        return
    fi
}
#==============================================================================


#==============================================================================
# Displays the number of data-mismatches detected
#==============================================================================
get_errors()
{
    if [ "$1" == "1" ]; then
        read_reg $REG_ERRORS1
    elif [ "$1" == "2" ]; then
        read_reg $REG_ERRORS2
    else
        echo "Bad parameter [$1] on get_errors()" 1>&2
        echo "0"
        return
    fi
}
#==============================================================================


#==============================================================================
# Causes the generator to simulate an error
#==============================================================================
sim_error()
{
    pcireg $REG_SIMERROR $1    
}
#==============================================================================




