<?php

namespace App\Livewire;

use App\Mail\SmtpTestMail;
use Illuminate\Contracts\View\View;
use Illuminate\Support\Facades\Mail;
use Livewire\Component;

class SmtpTestForm extends Component
{
    public string $to = '';

    public string $subject = '';

    public string $body = 'Hello, this is a test.';

    public string $contentType = 'text/plain';

    public string $contentTransferEncoding = '8bit';

    public function send(): void
    {
        $validated = $this->validate([
            'to' => ['required', 'email'],
            'subject' => ['required', 'string'],
            'body' => ['required', 'string'],
            'contentType' => ['required', 'in:text/plain,text/html'],
            'contentTransferEncoding' => ['required', 'in:8bit,base64'],
        ]);

        Mail::to($validated['to'])->send(new SmtpTestMail(
            $validated['subject'],
            $validated['body'],
            $validated['contentType'],
            $validated['contentTransferEncoding'],
        ));

        session()->flash('smtp-status', 'SMTP test message submitted to the configured mailer.');
    }

    public function render(): View
    {
        return view('livewire.smtp-test-form');
    }
}