   function hex_dump(buf)
      for i=1,math.ceil(#buf/16) * 16 do
         if (i-1) % 16 == 0 then io.write(string.format('%08X  ', i-1)) end
         io.write( i > #buf and '   ' or string.format('%02X ', buf:byte(i)) )
         if i %  8 == 0 then io.write(' ') end
         if i % 16 == 0 then io.write( buf:sub(i-16+1, i):gsub('%c','.'), '\n' ) end
      end
   end

hex_dump("now is the time for all good men to come to the aid of their computer system.")
