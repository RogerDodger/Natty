Number.prototype.zeropad = function(n) {
   var str = "" + this;
   var len = n - str.length;
   var pad = "";
   while (len-- > 0) {
      pad += "0";
   }
   return pad + str;
};
