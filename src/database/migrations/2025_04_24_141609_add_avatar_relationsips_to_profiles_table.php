<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('profiles', function (Blueprint $table) {
            $table->foreignId('selected_avatar_id')
                ->nullable()
                ->after('user_id')
                ->constrained('avatars')
                ->nullOnDelete();
        });
    }

    public function down(): void
    {
        Schema::table('profiles', function (Blueprint $table) {
            $table->dropForeign(['selected_avatar_id']);
            $table->dropColumn('selected_avatar_id');
        });
    }
};
