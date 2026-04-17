<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('tasks', function (Blueprint $table) {
            $table->id();
            $table->string('name')->unique();
            $table->string('directory');
            $table->string('scheduled_task_path');
            $table->string('type');
            $table->boolean('active')->default(true);
            $table->timestamps();
        });

        Schema::create('deployments', function (Blueprint $table) {
            $table->id();
            $table->foreignId('task_id')->constrained()->cascadeOnDelete();
            $table->string('triggered_by');
            $table->string('status');
            $table->timestamp('started_at')->nullable();
            $table->timestamp('completed_at')->nullable();
            $table->text('output')->nullable();
            $table->timestamps();
        });

        Schema::create('exhibitions', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->string('language_id');
            $table->string('status');
            $table->json('api_env')->nullable();
            $table->json('client_env')->nullable();
            $table->timestamp('synced_at')->nullable();
            $table->timestamps();
            $table->unique(['name', 'language_id']);
        });

        Schema::create('audit_log', function (Blueprint $table) {
            $table->id();
            $table->string('user')->nullable();
            $table->string('action');
            $table->string('target');
            $table->json('payload')->nullable();
            $table->timestamp('created_at')->useCurrent();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('audit_log');
        Schema::dropIfExists('exhibitions');
        Schema::dropIfExists('deployments');
        Schema::dropIfExists('tasks');
    }
};