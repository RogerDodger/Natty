String.prototype.zeropad = function (n) {
   var s = this;
   var l = n - s.length;
   while (l-- > 0) {
      s = s + '0';
   }
   return s;
}
