<?php

use Illuminate\Database\Migrations\Migration,
    Illuminate\Database\Schema\Blueprint,
    Illuminate\Support\Facades\Schema;

use App\Models\User;

class AddSaslSecretToUsersTable extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->string('sasl_secret')->nullable()->after('channels');
        });

        // Populate existing users
        User::chunk(100, function ($users) {
            foreach ($users as $user) {
                if (empty($user->sasl_secret)) {
                    $user->sasl_secret = User::generateSaslSecret();
                    $user->saveQuietly();
                }
            }
        });
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn('sasl_secret');
        });
    }
}
