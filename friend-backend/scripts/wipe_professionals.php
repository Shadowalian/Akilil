<?php

$m = @new mysqli('13.140.131.249', 'akilil', 'dd71f4af19c685416af966e0', 'akilil', 3306);
if ($m->connect_error) {
    fwrite(STDERR, 'connect: '.$m->connect_error.PHP_EOL);
    exit(1);
}
$m->set_charset('utf8mb4');

$r = $m->query("SELECT id, email, name FROM users WHERE role='professional'");
echo "pros_before=".$r->num_rows.PHP_EOL;
$ids = [];
while ($row = $r->fetch_assoc()) {
    $ids[] = (int) $row['id'];
    echo $row['id']."\t".$row['email']."\t".$row['name'].PHP_EOL;
}

if ($ids === []) {
    echo "nothing_to_wipe\n";
    exit(0);
}

$idList = implode(',', $ids);

$m->begin_transaction();
try {
    $steps = [
        "DELETE FROM appointments WHERE professional_user_id IN ($idList) OR user_id IN ($idList)",
        "DELETE FROM users WHERE id IN ($idList)",
    ];
    foreach ($steps as $sql) {
        if (!$m->query($sql)) {
            throw new RuntimeException($m->error.' :: '.$sql);
        }
        echo "ok: $sql (affected={$m->affected_rows})\n";
    }
    $m->commit();
} catch (Throwable $e) {
    $m->rollback();
    fwrite(STDERR, 'wipe_failed: '.$e->getMessage().PHP_EOL);
    exit(1);
}

$left = $m->query("SELECT COUNT(*) AS c FROM users WHERE role='professional'")->fetch_assoc()['c'];
$profiles = $m->query('SELECT COUNT(*) AS c FROM professional_profiles')->fetch_assoc()['c'];
echo "pros_after=$left profiles_after=$profiles\n";
