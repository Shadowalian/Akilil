<?php
mysqli_report(MYSQLI_REPORT_OFF);
$m = mysqli_init();
$m->options(MYSQLI_OPT_CONNECT_TIMEOUT, 10);
foreach ([['13.140.131.249', 'akilil', 'dd71f4af19c685416af966e0'], ['13.140.131.249', 'root', 'e8bb1794dd690bd7096345d4a7ac2be4']] as [$h,$u,$p]) {
    $ok = @$m->real_connect($h, $u, $p, 'akilil', 3306);
    echo "$u@$h => ".($ok ? 'ok' : $m->connect_error).PHP_EOL;
    if ($ok) { $m->close(); break; }
}
