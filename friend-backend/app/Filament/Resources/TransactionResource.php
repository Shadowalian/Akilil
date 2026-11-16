<?php

namespace App\Filament\Resources;

use App\Filament\Resources\TransactionResource\Pages;
use App\Models\Transaction;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Notifications\Notification;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;

class TransactionResource extends Resource
{
    protected static ?string $model = Transaction::class;
    protected static ?string $navigationIcon = 'heroicon-o-banknotes';
    protected static ?string $navigationGroup = 'Finance';
    protected static ?string $navigationLabel = 'Transactions';
    protected static ?int $navigationSort = 10;

    public static function form(Form $form): Form
    {
        return $form->schema([
            Forms\Components\Section::make('Transaction')
                ->schema([
                    Forms\Components\TextInput::make('id')->disabled(),
                    Forms\Components\Select::make('type')
                        ->options(['payment' => 'Payment', 'payout' => 'Payout', 'refund' => 'Refund', 'topup' => 'Top-up', 'subscription' => 'Subscription', 'adjustment' => 'Adjustment']),
                    Forms\Components\Select::make('status')
                        ->options(['pending' => 'Pending', 'processing' => 'Processing', 'succeeded' => 'Succeeded', 'failed' => 'Failed', 'cancelled' => 'Cancelled', 'refunded' => 'Refunded']),
                    Forms\Components\TextInput::make('amount_cents')->numeric(),
                    Forms\Components\TextInput::make('currency')->maxLength(3),
                    Forms\Components\TextInput::make('gateway')->maxLength(32),
                    Forms\Components\TextInput::make('gateway_reference')->maxLength(191),
                    Forms\Components\TextInput::make('failure_reason')->disabled(),
                ])
                ->columns(2),
        ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->defaultSort('created_at', 'desc')
            ->columns([
                Tables\Columns\TextColumn::make('id')->sortable(),
                Tables\Columns\TextColumn::make('created_at')->dateTime()->sortable(),
                Tables\Columns\TextColumn::make('user.name')->label('User')->searchable(),
                Tables\Columns\TextColumn::make('type')
                    ->badge()
                    ->color(fn (string $state) => match ($state) {
                        'payment' => 'success',
                        'payout'  => 'info',
                        'refund'  => 'warning',
                        default   => 'gray',
                    }),
                Tables\Columns\TextColumn::make('status')
                    ->badge()
                    ->color(fn (string $state) => match ($state) {
                        'succeeded'  => 'success',
                        'pending'    => 'warning',
                        'failed'     => 'danger',
                        'cancelled'  => 'gray',
                        'refunded'   => 'info',
                        default      => 'gray',
                    }),
                Tables\Columns\TextColumn::make('amount_cents')
                    ->formatStateUsing(fn ($state, $record) => number_format($state / 100, 2) . ' ' . $record->currency)
                    ->alignRight(),
                Tables\Columns\TextColumn::make('gateway'),
                Tables\Columns\TextColumn::make('gateway_reference')->limit(20),
            ])
            ->filters([
                Tables\Filters\SelectFilter::make('type')->options([
                    'payment' => 'Payment',
                    'topup' => 'Wallet top-up',
                    'payout' => 'Payout',
                    'refund' => 'Refund',
                    'subscription' => 'Subscription',
                    'adjustment' => 'Adjustment',
                ]),
                Tables\Filters\SelectFilter::make('status')->options([
                    'pending' => 'Pending', 'succeeded' => 'Succeeded', 'failed' => 'Failed',
                ]),
                Tables\Filters\SelectFilter::make('gateway')->options([
                    'stripe' => 'Stripe', 'chapa' => 'Chapa', 'telebirr' => 'Telebirr',
                ]),
                Tables\Filters\Filter::make('created_at')
                    ->form([
                        Forms\Components\DatePicker::make('from'),
                        Forms\Components\DatePicker::make('to'),
                    ])
                    ->query(fn ($q, array $data) => $q
                        ->when($data['from'] ?? null, fn ($q, $d) => $q->whereDate('created_at', '>=', $d))
                        ->when($data['to']   ?? null, fn ($q, $d) => $q->whereDate('created_at', '<=', $d))
                    ),
            ])
            ->headerActions([
                Tables\Actions\Action::make('export_csv')
                    ->label('Export CSV')
                    ->icon('heroicon-o-arrow-down-tray')
                    ->action(function () {
                        $rows = static::getModel()::orderBy('created_at', 'desc')->limit(10000)->get();
                        $csv = "id,created_at,user_id,type,status,amount_cents,currency,gateway\n";
                        foreach ($rows as $r) {
                            $csv .= "{$r->id},{$r->created_at},{$r->user_id},{$r->type},{$r->status},{$r->amount_cents},{$r->currency},{$r->gateway}\n";
                        }
                        return response()->streamDownload(fn () => print $csv, 'transactions.csv', ['Content-Type' => 'text/csv']);
                    }),
            ])
            ->actions([
                Tables\Actions\Action::make('refund')
                    ->icon('heroicon-o-arrow-uturn-left')
                    ->color('warning')
                    ->visible(fn (Transaction $r) => $r->status === 'succeeded' && $r->type === 'payment')
                    ->requiresConfirmation()
                    ->form([Forms\Components\TextInput::make('reason')->required()])
                    ->action(function (Transaction $record, array $data) {
                        // STUB: Task 9 wires the actual gateway refund call. For
                        // now we record the intent and update the status; the
                        // admin sees the failed refund in the gateway response.
                        $record->update([
                            'status'         => 'refunded',
                            'failure_reason' => 'REFUND REQUESTED: ' . $data['reason'] . ' (gateway wired in Task 9)',
                        ]);
                        Notification::make()->title('Refund recorded (gateway stub)')->warning()->send();
                    }),
            ]);
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListTransactions::route('/'),
        ];
    }
}