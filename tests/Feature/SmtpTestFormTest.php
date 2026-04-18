<?php

namespace Tests\Feature;

use App\Livewire\SmtpTestForm;
use App\Mail\SmtpTestMail;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Mail;
use Livewire\Livewire;
use Tests\TestCase;

class SmtpTestFormTest extends TestCase
{
    use RefreshDatabase;

    public function test_smtp_form_sends_a_test_mail_with_the_requested_options(): void
    {
        Mail::fake();

        Livewire::test(SmtpTestForm::class)
            ->set('to', 'recipient@example.com')
            ->set('subject', 'SMTP check')
            ->set('body', '<p>Hello</p>')
            ->set('contentType', 'text/html')
            ->set('contentTransferEncoding', 'base64')
            ->call('send');

        Mail::assertSent(SmtpTestMail::class, function (SmtpTestMail $mail): bool {
            return $mail->hasTo('recipient@example.com')
                && $mail->subjectLine === 'SMTP check'
                && $mail->bodyText === '<p>Hello</p>'
                && $mail->contentType === 'text/html'
                && $mail->contentTransferEncoding === 'base64';
        });
    }

    public function test_smtp_form_validates_email_and_field_options(): void
    {
        Livewire::test(SmtpTestForm::class)
            ->set('to', 'not-an-email')
            ->set('subject', '')
            ->set('body', '')
            ->set('contentType', 'application/json')
            ->set('contentTransferEncoding', 'quoted-printable')
            ->call('send')
            ->assertHasErrors(['to', 'subject', 'body', 'contentType', 'contentTransferEncoding']);
    }
}