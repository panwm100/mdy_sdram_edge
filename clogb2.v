function integer clogb2(input integer depth);
begin
   if(depth==0)
       clogb2=1;
   else if(depth!=0)
       for(clogb2=0; depth>0;clogb2=clogb2+1)
             depth=depth>>1;
end
endfunction
