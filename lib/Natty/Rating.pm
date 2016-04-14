package Natty::Rating;
use Mojo::Base '-strict';

sub MU_INIT { 25 }

sub SIGMA_INIT { MU_INIT() / 3 }

sub BETA { SIGMA_INIT() / 2 }

sub K { 0.0001 }

1;
