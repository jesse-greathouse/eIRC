<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Str;

return new class extends Migration
{
    public function up(): void
    {
        // Drop realname if it exists (dev safety)
        if (Schema::hasColumn('users', 'realname')) {
            Schema::table('users', function (Blueprint $table) {
                $table->dropColumn('realname');
            });
        }

        // Step 1: Add realname as nullable, no unique yet
        Schema::table('users', function (Blueprint $table) {
            $table->string('realname')->nullable()->after('id');
        });

        // Step 2: Backfill unique realname values
        DB::table('users')->orderBy('id')->each(function ($user) {
            $base = Str::slug($user->name ?? 'user', '_');
            $realname = $base;
            $i = 1;

            while (DB::table('users')->where('realname', $realname)->where('id', '!=', $user->id)->exists()) {
                $realname = $base . '_' . $i++;
            }

            DB::table('users')->where('id', $user->id)->update(['realname' => $realname]);
        });

        // Step 3: Alter realname to be non-nullable and unique
        Schema::table('users', function (Blueprint $table) {
            $table->string('realname')->nullable(false)->unique()->change();
        });

        // Backfill NULL nicknames with unique anonymous nicks
        DB::table('users')->whereNull('nick')->orderBy('id')->get()->each(function ($user) {
            $anonymousNick = 'anonymous_' . Str::uuid()->toString();
            DB::table('users')->where('id', $user->id)->update(['nick' => $anonymousNick]);
        });

        // Step 4: Drop unique constraint from nick and make it not nullable
        Schema::table('users', function (Blueprint $table) {
            $table->dropUnique(['nick']); // Ensure correct index name if needed
            $table->string('nick')->nullable(false)->change();
        });
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn('realname');
            $table->string('nick')->nullable()->change();
            $table->unique('nick'); // Add unique back if needed
        });
    }
};
